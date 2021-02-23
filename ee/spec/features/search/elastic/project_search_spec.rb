# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project elastic search', :js, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe 'searching', :sidekiq_inline do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_path(project)
    end

    it 'finds issues' do
      create(:issue, project: project, title: 'Test searching for an issue')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Issues')

      expect(page).to have_selector('.results', text: 'Test searching for an issue')
    end

    it 'finds merge requests' do
      create(:merge_request, source_project: project, target_project: project, title: 'Test searching for an MR')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Merge requests')

      expect(page).to have_selector('.results', text: 'Test searching for an MR')
    end

    it 'finds milestones' do
      create(:milestone, project: project, title: 'Test searching for a milestone')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Milestones')

      expect(page).to have_selector('.results', text: 'Test searching for a milestone')
    end

    it 'finds wiki pages' do
      project.wiki.create_page('test.md', 'Test searching for a wiki page')
      project.wiki.index_wiki_blobs
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Wiki')

      expect(page).to have_selector('.results', text: 'Test searching for a wiki page')
    end

    it 'finds notes' do
      create(:note, project: project, note: 'Test searching for a comment')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Comments')

      expect(page).to have_selector('.results', text: 'Test searching for a comment')
    end

    it 'finds commits' do
      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!

      submit_search('initial')
      select_search_scope('Commits')

      expect(page).to have_selector('.results', text: 'Initial commit')
    end

    it 'finds blobs' do
      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!

      submit_search('def')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'def username_regex')
    end
  end

  describe 'displays Advanced Search status' do
    before do
      sign_in(user)

      visit search_path(project_id: project.id, repository_ref: repository_ref)
    end

    context "when `repository_ref` isn't the default branch" do
      let(:repository_ref) { Gitlab::Git::BLANK_SHA }

      it 'displays that advanced search is disabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="false"]')

        default_branch_link = page.find('a[data-testid="es-search-default-branch"]')
        params = CGI.parse(URI.parse(default_branch_link[:href]).query)

        expect(default_branch_link).to have_content(project.default_branch)
        expect(params).not_to include(:repository_ref)
      end
    end

    context "when `repository_ref` is unset" do
      let(:repository_ref) { "" }

      it 'displays that advanced search is enabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="true"]')
      end
    end

    context "when `repository_ref` is the default branch" do
      let(:repository_ref) { project.default_branch }

      it 'displays that advanced search is enabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="true"]')
      end
    end
  end
end

RSpec.describe 'Project elastic search redactions', :elastic, :js do
  it_behaves_like 'a redacted search results page' do
    let(:search_path) { project_path(public_restricted_project) }
  end
end
