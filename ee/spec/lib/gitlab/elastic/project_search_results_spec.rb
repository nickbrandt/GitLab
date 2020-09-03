# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::ProjectSearchResults, :elastic do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:query) { 'hello world' }
  let(:repository_ref) { nil }
  let(:filters) { {} }

  subject(:results) { described_class.new(user, query, project: project, repository_ref: repository_ref, filters: filters) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe 'initialize with empty ref' do
    let(:repository_ref) { '' }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq('master') }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:repository_ref) { 'refs/heads/test' }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(repository_ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe "search", :sidekiq_inline do
    let_it_be(:project) { create(:project, :public, :repository, :wiki_repo) }
    let_it_be(:private_project) { create(:project, :repository, :wiki_repo) }

    before do
      [project, private_project].each do |project|
        create(:note, note: 'bla-bla term', project: project)
        project.wiki.create_page('index_page', 'term')
        project.wiki.index_wiki_blobs
      end

      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    it "returns correct amounts" do
      result = described_class.new(user, 'term', project: project)
      expect(result.notes_count).to eq(1)
      expect(result.wiki_blobs_count).to eq(1)
      expect(result.blobs_count).to eq(1)

      result = described_class.new(user, 'initial', project: project)
      expect(result.commits_count).to eq(1)
    end

    context 'visibility checks' do
      let_it_be(:project) { create(:project, :public, :wiki_repo) }
      let(:query) { 'term' }

      before do
        project.add_guest(user)
      end

      it 'shows wiki for guests' do
        expect(results.wiki_blobs_count).to eq(1)
      end
    end

    context 'filtering' do
      include_examples 'search issues scope filters by state' do
        let!(:project) { create(:project, :public) }
        let!(:closed_issue) { create(:issue, :closed, project: project, title: 'foo closed') }
        let!(:opened_issue) { create(:issue, :opened, project: project, title: 'foo opened') }
        let(:query) { 'foo' }

        before do
          ensure_elasticsearch_index!
        end
      end
    end
  end

  describe "search for commits in non-default branch" do
    let(:project) { create(:project, :public, :repository, visibility) }
    let(:visibility) { :repository_enabled }
    let(:query) { 'initial' }
    let(:repository_ref) { 'test' }

    subject(:commits) { results.objects('commits') }

    it 'finds needed commit' do
      expect(results.commits_count).to eq(1)
    end

    it 'responds to total_pages method' do
      expect(commits.total_pages).to eq(1)
    end

    context 'disabled repository' do
      let(:visibility) { :repository_disabled }

      it 'hides commits from members' do
        project.add_reporter(user)

        is_expected.to be_empty
      end

      it 'hides commits from non-members' do
        is_expected.to be_empty
      end
    end

    context 'private repository' do
      let(:visibility) { :repository_private }

      it 'shows commits to members' do
        project.add_reporter(user)

        is_expected.not_to be_empty
      end

      it 'hides commits from non-members' do
        is_expected.to be_empty
      end
    end
  end

  describe 'search for blobs in non-default branch' do
    let(:project) { create(:project, :public, :repository, :repository_private) }
    let(:query) { 'initial' }
    let(:repository_ref) { 'test' }

    subject(:blobs) { results.objects('blobs') }

    it 'always returns zero results' do
      expect_any_instance_of(Gitlab::FileFinder).to receive(:find).never

      expect(blobs).to be_empty
    end
  end

  describe 'confidential issues', :sidekiq_might_not_need_inline do
    include_examples 'access restricted confidential issues' do
      before do
        ensure_elasticsearch_index!
      end
    end
  end

  context 'user search' do
    let(:query) { project.owner.username }

    before do
      expect(Gitlab::ProjectSearchResults).to receive(:new).and_call_original
    end

    it { expect(results.objects('users')).to eq([project.owner]) }
    it { expect(results.limited_users_count).to eq(1) }

    describe 'pagination' do
      let(:query) { }

      let_it_be(:user2) { create(:user).tap { |u| project.add_user(u, Gitlab::Access::REPORTER) } }

      it 'returns the correct page of results' do
        # UsersFinder defaults to order_id_desc, the newer result will be first
        expect(results.objects('users', page: 1, per_page: 1)).to eq([user2])
        expect(results.objects('users', page: 2, per_page: 1)).to eq([project.owner])
      end

      it 'returns the correct number of results for one page' do
        expect(results.objects('users', page: 1, per_page: 2).count).to eq(2)
      end
    end
  end

  context 'query performance' do
    let(:project) { create(:project, :public, :repository, :wiki_repo) }
    let(:query) { '*' }

    before do
      # wiki_blobs method checks to see if there is a wiki page before doing
      # the search
      create(:wiki_page, wiki: project.wiki)
    end

    include_examples 'does not hit Elasticsearch twice for objects and counts', %w|notes blobs wiki_blobs commits issues merge_requests milestones|
  end
end
