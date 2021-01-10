# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::OpenIssuesCountService, :use_clean_rails_memory_store_caching do
  let_it_be(:group) { create(:group, :public)}
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, :opened, project: project) }
  let_it_be(:confidential) { create(:issue, :opened, confidential: true, project: project) }
  let_it_be(:closed) { create(:issue, :closed, project: project) }

  subject { described_class.new(group, user) }

  describe '#self.query' do
    before do
      allow(IssuesFinder).to receive(:new).and_call_original
    end

    it 'uses the IssuesFinder to scope issues' do
      expect(IssuesFinder)
        .to receive(:new)
        .with(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true, public_only: true)

      subject.count
    end
  end

  describe '#count' do
    context 'when user is nil' do
      it 'does not include confidential issues in the issue count' do
        expect(described_class.new(group).count).to eq(1)
      end
    end

    context 'when user is provided' do
      let(:total_count_key) { subject.cache_key(described_class::TOTAL_COUNT_KEY) }

      context 'when user can read confidential issues' do
        before do
          group.add_reporter(user)
          project.add_reporter(user)
        end

        it 'returns the right count with confidential issues' do
          expect(subject.count).to eq(2)
        end

        it 'uses total_open_issues_count cache key' do
          expect(subject.cache_key_name).to eq('group_total_open_issues_count')
        end

        context 'when cache is empty' do
          before do
            Rails.cache.delete(total_count_key)
          end

          it 'refreshes cache keys correctly' do
            subject.count

            expect(Rails.cache.read(total_count_key)).to eq(2)
          end
        end

        context 'when count is over the threshold value' do
          before do
            Rails.cache.write(total_count_key, 12345)
          end

          it 'does not refresh cache' do
            expect(Rails.cache).not_to receive(:write)

            subject.count
          end
        end
      end

      context 'when user cannot read confidential issues' do
        before do
          group.add_guest(user)
          project.add_guest(user)
        end

        it 'does not include confidential issues' do
          expect(subject.count).to eq(1)
        end

        it 'uses public_open_issues_count cache key' do
          expect(subject.cache_key_name).to eq('group_public_open_issues_count')
        end

        context 'when cache is empty' do
          let(:public_count_key) { subject.cache_key(described_class::PUBLIC_COUNT_KEY) }

          before do
            Rails.cache.delete(public_count_key)
          end

          it 'refreshes cache keys correctly' do
            subject.count

            expect(Rails.cache.read(public_count_key)).to eq(1)
          end
        end
      end
    end
  end
end
