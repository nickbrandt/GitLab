require 'spec_helper'

describe 'Global elastic search', :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'an efficient database result' do
    it 'avoids N+1 database queries' do
      create(object, creation_args)
      Gitlab::Elastic::Helper.refresh_index

      control_count = ActiveRecord::QueryRecorder.new { visit path }.count

      create_list(object, 10, creation_args)
      Gitlab::Elastic::Helper.refresh_index

      control_count = control_count + (10 * query_count_multiplier) + 1

      expect { visit path }.not_to exceed_query_limit(control_count)
    end
  end

  describe 'I do not overload the database' do
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
      # Each Project requires 5 extra queries: one for each "count" (forks,
      # open MRs, open Issues) and twice for access level. This should be fixed
      # per https://gitlab.com/gitlab-org/gitlab/issues/34457
      let(:query_count_multiplier) { 5 }

      it_behaves_like 'an efficient database result'
    end

    context 'searching merge requests' do
      let(:object) { :merge_request }
      let(:creation_args) { { title: 'initial' } }
      let(:path) { search_path(search: 'initial*', scope: 'merge_requests') }
      let(:query_count_multiplier) { 0 }

      it_behaves_like 'an efficient database result'
    end

    context 'searching milestones' do
      let(:object) { :milestone }
      let(:creation_args) { { project: project } }
      let(:path) { search_path(search: 'milestone*', scope: 'milestones') }
      let(:query_count_multiplier) { 0 }

      it_behaves_like 'an efficient database result'
    end
  end

  describe 'I search through the issues and I see pagination' do
    before do
      create_list(:issue, 21, project: project, title: 'initial')

      Gitlab::Elastic::Helper.refresh_index
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('initial')
      select_search_scope('Issues')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the notes and I see pagination' do
    before do
      issue = create(:issue, project: project, title: 'initial')
      create_list(:note, 21, noteable: issue, project: project, note: 'foo')

      Gitlab::Elastic::Helper.refresh_index
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('foo')
      select_search_scope('Comments')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the blobs' do
    let(:project_2) { create(:project, :repository, :wiki_repo) }

    before do
      project.repository.index_commits_and_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds files" do
      visit dashboard_projects_path

      submit_search('application.js')
      select_search_scope('Code')

      expect(page).to have_selector('.file-content .code')

      expect(page).to have_selector("span.line[lang='javascript']")
    end

    it 'Ignores nonexistent projects from stale index' do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

      project_2.repository.create_file(
        user,
        'thing.txt',
        ' function application.js ',
        message: 'supercalifragilisticexpialidocious',
        branch_name: 'master')

      project_2.repository.index_commits_and_blobs
      Gitlab::Elastic::Helper.refresh_index
      project_2.destroy

      visit dashboard_projects_path

      submit_search('application.js')

      expect(page).not_to have_content 'supercalifragilisticexpialidocious'
    end
  end

  describe 'I search through the wiki blobs' do
    before do
      project.wiki.create_page('test.md', '# term')
      project.wiki.index_wiki_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds files" do
      visit dashboard_projects_path

      submit_search('term')
      select_search_scope('Wiki')

      expect(page).to have_selector('.file-content .code')

      expect(page).to have_selector("span.line[lang='markdown']")
    end
  end

  describe 'I search through the commits' do
    before do
      project.repository.index_commits_and_blobs
      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds commits" do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expect(page).to have_selector('.commit-row-description')
      expect(page).to have_selector('.project-namespace')
    end

    it 'shows proper page 2 results' do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expected_message = "Add directory structure for tree_helper spec"

      expect(page).not_to have_content(expected_message)

      click_link 'Next'

      expect(page).to have_content(expected_message)
    end
  end

  describe 'I search globally', :js do
    before do
      create(:issue, project: project, title: 'project issue')
      Gitlab::Elastic::Helper.refresh_index

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

describe 'Global elastic search redactions', :elastic do
  it_behaves_like 'a redacted search results page' do
    let(:search_path) { explore_root_path }
  end
end
