# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global elastic search', :elastic, :sidekiq_inline do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'an efficient database result' do
    it 'avoids N+1 database queries' do
      create(object, *creation_traits, creation_args)

      ensure_elasticsearch_index!

      control_count = ActiveRecord::QueryRecorder.new { visit path }.count
      expect(page).to have_css('.search-results') # Confirm there are search results to prevent false positives

      create_list(object, 10, *creation_traits, creation_args)

      ensure_elasticsearch_index!

      control_count = control_count + (10 * query_count_multiplier) + 1

      expect { visit path }.not_to exceed_query_limit(control_count)
      expect(page).to have_css('.search-results') # Confirm there are search results to prevent false positives
    end
  end

  describe 'I do not overload the database' do
    let(:creation_traits) { [] }

    context 'searching issues' do
      let(:object) { :issue }
      let(:creation_args) { { project: project, title: 'initial' } }
      let(:path) { search_path(search: 'initial', scope: 'issues') }
      let(:query_count_multiplier) { 0 }

      it_behaves_like 'an efficient database result'
    end

    context 'searching projects' do
      let(:object) { :project }
      let(:creation_args) { { namespace: user.namespace } }
      let(:path) { search_path(search: 'project*', scope: 'projects') }
      # Each Project requires 4 extra queries: one for each "count" (forks,
      # open MRs, open Issues and access levels). This should be fixed per
      # https://gitlab.com/gitlab-org/gitlab/issues/34457
      let(:query_count_multiplier) { 4 }

      it_behaves_like 'an efficient database result'
    end

    context 'searching merge requests' do
      let(:object) { :merge_request }
      let(:creation_traits) { [:sequence_source_branch] }
      let(:creation_args) { { source_project: project, title: 'initial' } }
      let(:path) { search_path(search: '*', scope: 'merge_requests') }
      let(:query_count_multiplier) { 0 }

      it_behaves_like 'an efficient database result'
    end

    context 'searching milestones' do
      let(:object) { :milestone }
      let(:creation_args) { { project: project } }
      let(:path) { search_path(search: '*', scope: 'milestones') }
      let(:query_count_multiplier) { 0 }

      it_behaves_like 'an efficient database result'
    end
  end

  describe 'I search through the issues and I see pagination', :js do
    before do
      create_list(:issue, 21, project: project, title: 'initial')

      ensure_elasticsearch_index!
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('initial')
      select_search_scope('Issues')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the notes and I see pagination', :js do
    before do
      issue = create(:issue, project: project, title: 'initial')
      create_list(:note, 21, noteable: issue, project: project, note: 'foo')

      ensure_elasticsearch_index!
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('foo')
      select_search_scope('Comments')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the blobs', :js do
    let(:project_2) { create(:project, :repository, :wiki_repo) }

    before do
      project.repository.index_commits_and_blobs

      ensure_elasticsearch_index!
    end

    it "finds files" do
      visit dashboard_projects_path

      submit_search('application.js')
      select_search_scope('Code')

      expect(page).to have_selector('.file-content .code')

      expect(page).to have_selector("span.line[lang='javascript']")
    end

    it 'ignores nonexistent projects from stale index' do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

      project_2.repository.create_file(
        user,
        'thing.txt',
        ' function application.js ',
        message: 'supercalifragilisticexpialidocious',
        branch_name: 'master')

      project_2.repository.index_commits_and_blobs

      ensure_elasticsearch_index!

      project_2.destroy!

      visit dashboard_projects_path

      submit_search('application.js')

      expect(page).not_to have_content 'supercalifragilisticexpialidocious'
    end
  end

  describe 'I search through the wiki blobs', :js do
    before do
      project.wiki.create_page('test.md', '# term')
      project.wiki.index_wiki_blobs

      ensure_elasticsearch_index!
    end

    it "finds wiki pages" do
      visit dashboard_projects_path

      submit_search('term')
      select_search_scope('Wiki')

      expect(page).to have_selector('.search-result-row .description', text: '# term')
      expect(page).to have_link('test')
    end
  end

  describe 'I search through the commits', :js do
    before do
      project.repository.index_commits_and_blobs

      ensure_elasticsearch_index!
    end

    it "finds commits" do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expect(page).to have_selector('.commit-row-message')
      expect(page).to have_selector('.project-namespace')
    end

    it 'shows proper page 2 results' do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expected_message = "Merge branch 'tree_helper_spec' into 'master'"

      expect(page).not_to have_content(expected_message)

      click_link 'Next'

      expect(page).to have_content(expected_message)
    end
  end

  describe 'I search globally', :js do
    before do
      create(:issue, project: project, title: 'project issue')
      ensure_elasticsearch_index!

      visit dashboard_projects_path

      submit_search('project')
    end

    it 'displays result counts for all categories' do
      expect(page).to have_content('Projects 1')
      expect(page).to have_content('Issues 1')
      expect(page).to have_content('Merge requests 0')
      expect(page).to have_content('Milestones 0')
      expect(page).to have_content('Comments 0')
      expect(page).to have_content('Code 0')
      expect(page).to have_content('Commits 0')
      expect(page).to have_content('Wiki 0')
      expect(page).to have_content('Users 0')
    end
  end
end

RSpec.describe 'Global elastic search redactions', :elastic, :js do
  context 'when block_anonymous_global_searches is disabled' do
    before do
      stub_feature_flags(block_anonymous_global_searches: false)
    end

    it_behaves_like 'a redacted search results page' do
      let(:search_path) { explore_root_path }
    end
  end

  context 'when block_anonymous_global_searches is enabled' do
    it_behaves_like 'a redacted search results page', include_anonymous: false do
      let(:search_path) { explore_root_path }
    end
  end
end
