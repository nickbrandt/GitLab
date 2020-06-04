# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::ProjectSearchResults, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:query) { 'hello world' }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe 'initialize with empty ref' do
    subject(:results) { described_class.new(user, query, project, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq('master') }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }

    subject(:results) { described_class.new(user, query, project, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe "search", :sidekiq_might_not_need_inline do
    it "returns correct amounts" do
      project = create :project, :public, :repository, :wiki_repo
      project1 = create :project, :public, :repository, :wiki_repo

      project.repository.index_commits_and_blobs

      # Notes
      create :note, note: 'bla-bla term', project: project
      # The note in the project you have no access to
      create :note, note: 'bla-bla term', project: project1

      # Wiki
      project.wiki.create_page('index_page', 'term')
      project.wiki.index_wiki_blobs
      project1.wiki.create_page('index_page', ' term')
      project1.wiki.index_wiki_blobs

      ensure_elasticsearch_index!

      result = described_class.new(user, 'term', project)
      expect(result.notes_count).to eq(1)
      expect(result.wiki_blobs_count).to eq(1)
      expect(result.blobs_count).to eq(1)

      result1 = described_class.new(user, 'initial', project)
      expect(result1.commits_count).to eq(1)
    end

    context 'visibility checks' do
      it 'shows wiki for guests' do
        project = create :project, :public, :wiki_repo
        guest = create :user
        project.add_guest(guest)

        # Wiki
        project.wiki.create_page('index_page', 'term')
        project.wiki.index_wiki_blobs

        ensure_elasticsearch_index!

        result = described_class.new(guest, 'term', project)
        expect(result.wiki_blobs_count).to eq(1)
      end
    end
  end

  describe "search for commits in non-default branch" do
    let(:project) { create(:project, :public, :repository, visibility) }
    let(:visibility) { :repository_enabled }
    let(:result) { described_class.new(user, 'initial', project, 'test') }

    subject(:commits) { result.objects('commits') }

    it 'finds needed commit' do
      expect(result.commits_count).to eq(1)
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
    let(:result) { described_class.new(user, 'initial', project, 'test') }

    subject(:blobs) { result.objects('blobs') }

    it 'always returns zero results' do
      expect_any_instance_of(Gitlab::FileFinder).to receive(:find).never

      expect(blobs).to be_empty
    end
  end

  describe 'confidential issues', :sidekiq_might_not_need_inline do
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

    before do
      ensure_elasticsearch_index!
    end

    it 'does not list project confidential issues for non project members' do
      results = described_class.new(non_member, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists project confidential issues for author' do
      results = described_class.new(author, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for assignee' do
      results = described_class.new(assignee, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for project members' do
      project.add_developer(member)

      results = described_class.new(member, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end

    it 'does not list project confidential issues for project members with guest role' do
      project.add_guest(member)

      results = described_class.new(member, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists all project issues for admin' do
      results = described_class.new(admin, query, project)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end
  end

  context 'user search' do
    subject(:results) { described_class.new(user, query, project) }

    let(:query) { project.owner.username }

    before do
      expect(Gitlab::ProjectSearchResults).to receive(:new).and_call_original
    end

    it { expect(results.objects('users')).to eq([project.owner]) }
    it { expect(results.limited_users_count).to eq(1) }

    describe 'pagination' do
      let(:query) {}

      let!(:user2) { create(:user).tap { |u| project.add_user(u, Gitlab::Access::REPORTER) } }

      it 'returns the correct page of results' do
        expect(results.objects('users', page: 1, per_page: 1)).to eq([project.owner])
        expect(results.objects('users', page: 2, per_page: 1)).to eq([user2])
      end

      it 'returns the correct number of results for one page' do
        expect(results.objects('users', page: 1, per_page: 2).count).to eq(2)
      end
    end
  end
end
