# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IssuablesCountForState, :use_clean_rails_memory_store_caching do
  let(:finder) do
    double(:finder, current_user: nil, params: {}, count_by_state: { opened: 2, closed: 1 })
  end

  let(:project) { nil }
  let(:fast_fail) { nil }
  let(:counter) { described_class.new(finder, project, fast_fail: fast_fail) }

  describe 'project given' do
    let(:project) { build(:project) }

    it 'provides the project' do
      expect(counter.project).to eq(project)
    end
  end

  describe '.declarative_policy_class' do
    subject { described_class.declarative_policy_class }

    it { is_expected.to eq('IssuablePolicy') }
  end

  describe '#for_state_or_opened' do
    it 'returns the number of issuables for the given state' do
      expect(counter.for_state_or_opened(:closed)).to eq(1)
    end

    it 'returns the number of open issuables when no state is given' do
      expect(counter.for_state_or_opened).to eq(2)
    end

    it 'returns the number of open issuables when a nil value is given' do
      expect(counter.for_state_or_opened(nil)).to eq(2)
    end
  end

  describe '#[]' do
    it 'returns the number of issuables for the given state' do
      expect(counter[:closed]).to eq(1)
    end

    it 'casts valid states from Strings to Symbols' do
      expect(counter['closed']).to eq(1)
    end

    it 'returns 0 when using an invalid state name as a String' do
      expect(counter['kittens']).to be_zero
    end

    context 'fast_fail enabled' do
      let(:fast_fail) { true }

      it 'returns the expected value' do
        expect(counter[:closed]).to eq(1)
      end

      it 'returns -1 when the database times out' do
        expect(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

        expect(counter[:closed]).to eq(-1)
      end
    end
  end

  context 'when store_in_redis_cache is `true`', :clean_gitlab_redis_cache do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:states_count) { { opened: 1, closed: 1, all: 2 } }
    let_it_be(:cache_options) { { expires_in: 10.minutes } }

    let(:params) { {} }

    subject do
      described_class.new(finder, fast_fail: true, store_in_redis_cache: true )
    end

    shared_examples 'calculating counts without caching' do
      it 'does not store in redis store' do
        expect(Rails.cache).not_to receive(:fetch)
        subject[:all]
      end
    end

    context 'with issues' do
      let(:finder) { IssuesFinder.new(user, params) }

      shared_examples 'issues states with parent' do
        let(:visibility) { nil }
        let(:cache_key) { [parent_type, parent.id, 'IssuesFinder', visibility] }

        before do
          allow(Rails.cache).to receive(:fetch).and_return(states_count)
        end

        context 'when user has the right permissions' do
          let(:visibility) { 'total' }

          before do
            allow_next_instance_of(described_class) do |counter|
              allow(counter).to receive(:parent).and_return(parent)
              allow(counter).to receive(:user_is_at_least_reporter?).and_return(true)
            end
          end

          it 'stores cache in redis store' do
            expect(Rails.cache).to receive(:fetch).with(cache_key, cache_options)
            subject[:all]
          end
        end

        context 'when user is a guest' do
          let(:visibility) { 'public' }

          before do
            allow_next_instance_of(described_class) do |counter|
              allow(counter).to receive(:parent).and_return(parent)
              allow(counter).to receive(:user_is_at_least_reporter?).and_return(false)
            end
          end

          it 'stores cache in redis store' do
            expect(Rails.cache).to receive(:fetch).with(cache_key, cache_options)
            subject[:all]
          end
        end

        it 'returns -1 when the database times out' do
          expect(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

          expect(subject[:closed]).to eq(-1)
          expect(Rails.cache.read(cache_key)).to be_nil
        end
      end

      context 'when parent is not present' do
        before do
          allow(IssuesFinder).to receive_message_chain(:params, :parent).and_return(nil)
        end

        it_behaves_like 'calculating counts without caching'
      end

      context 'when params include search filters' do
        before do
          params[:assignee_id] = user.id
        end

        it_behaves_like 'calculating counts without caching'
      end

      it_behaves_like 'issues states with parent' do
        let(:parent) { project }
        let(:parent_type) { 'project' }
      end

      it_behaves_like 'issues states with parent' do
        let(:parent) { group }
        let(:parent_type) { 'group' }
      end
    end

    context 'with merge requests' do
      let(:cache_key) { [parent_type, parent.id, 'MergeRequestsFinder'] }
      let(:finder) { MergeRequestsFinder.new(user, params) }

      before do
        allow_next_instance_of(described_class) do |counter|
          allow(counter).to receive(:parent).and_return(parent)
        end
      end

      shared_examples 'merge request states with parent' do
        it 'stores cache in redis store' do
          allow(Rails.cache).to receive(:fetch).and_return(states_count)
          expect(Rails.cache).to receive(:fetch).with(cache_key, cache_options)
          subject[:all]
        end

        it 'returns -1 when the database times out' do
          expect(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

          expect(subject[:closed]).to eq(-1)
          expect(Rails.cache.read(cache_key)).to be_nil
        end
      end

      context 'when parent is not present' do
        let(:parent) { nil }

        it_behaves_like 'calculating counts without caching'
      end

      context 'when params include search filters' do
        let(:parent) { group }

        before do
          params[:assignee_id] = user.id
        end

        it_behaves_like 'calculating counts without caching'
      end

      it_behaves_like 'merge request states with parent' do
        let(:parent_type) { 'group' }
        let(:parent) { group }
      end

      it_behaves_like 'merge request states with parent' do
        let(:parent_type) { 'project' }
        let(:parent) { project }
      end
    end
  end
end
