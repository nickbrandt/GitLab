# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::GroupSearchResults, :elastic do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::GUEST) } }
  let(:filters) { {} }
  let(:query) { '*' }

  subject(:results) { described_class.new(user, query, Project.all, group: group, filters: filters) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'issues search', :sidekiq_inline do
    let!(:project) { create(:project, :public, group: group) }
    let!(:closed_issue) { create(:issue, :closed, project: project, title: 'foo closed') }
    let!(:opened_issue) { create(:issue, :opened, project: project, title: 'foo opened') }
    let(:query) { 'foo' }

    include_examples 'search issues scope filters by state' do
      before do
        ensure_elasticsearch_index!
      end
    end
  end

  context 'user search' do
    let(:query) { guest.username }

    before do
      expect(Gitlab::GroupSearchResults).to receive(:new).and_call_original
    end

    it { expect(results.objects('users')).to contain_exactly(guest) }
    it { expect(results.limited_users_count).to eq(1) }

    describe 'pagination' do
      let(:query) {}

      let_it_be(:user2) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::REPORTER) } }

      it 'returns the correct page of results' do
        expect(results.objects('users', page: 1, per_page: 1)).to contain_exactly(user2)
        expect(results.objects('users', page: 2, per_page: 1)).to contain_exactly(guest)
      end

      it 'returns the correct number of results for one page' do
        expect(results.objects('users', page: 1, per_page: 2).count).to eq(2)
      end
    end
  end

  context 'query performance' do
    include_examples 'does not hit Elasticsearch twice for objects and counts', %w|projects notes blobs wiki_blobs commits issues merge_requests milestones|
  end
end
