require 'spec_helper'

describe 'Project elastic search', :js, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_maintainer(user)
    sign_in(user)

    visit project_path(project)
  end

  describe 'searching' do
    it 'finds issues' do
      create(:issue, project: project, title: 'Test searching for an issue')

      submit_search('Test')
      select_search_scope('Issues')

      expect(page).to have_selector('.results', text: 'Test searching for an issue')
    end

    it 'finds merge requests' do
      create(:merge_request, source_project: project, target_project: project, title: 'Test searching for an MR')

      submit_search('Test')
      select_search_scope('Merge requests')

      expect(page).to have_selector('.results', text: 'Test searching for an MR')
    end

    it 'finds milestones' do
      create(:milestone, project: project, title: 'Test searching for a milestone')

      submit_search('Test')
      select_search_scope('Milestones')

      expect(page).to have_selector('.results', text: 'Test searching for a milestone')
    end

    it 'finds wiki pages' do
      project.wiki.create_page('test.md', 'Test searching for a wiki page')
      project.wiki.index_wiki_blobs

      submit_search('Test')
      select_search_scope('Wiki')

      expect(page).to have_selector('.results', text: 'Test searching for a wiki page')
    end

    it 'finds notes' do
      create(:note, project: project, note: 'Test searching for a comment')

      submit_search('Test')
      select_search_scope('Comments')

      expect(page).to have_selector('.results', text: 'Test searching for a comment')
    end

    it 'finds commits' do
      project.repository.index_commits_and_blobs

      submit_search('initial')
      select_search_scope('Commits')

      expect(page).to have_selector('.results', text: 'Initial commit')
    end

    it 'finds blobs' do
      project.repository.index_commits_and_blobs

      submit_search('def')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'def username_regex')
    end
  end
end

describe 'Project elastic search redactions', :elastic do
  it_behaves_like 'a redacted search results page' do
    let(:search_path) { project_path(public_restricted_project) }
  end
end
