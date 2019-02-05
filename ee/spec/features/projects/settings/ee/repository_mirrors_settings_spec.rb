require 'spec_helper'

describe 'Project settings > [EE] repository' do
  include Select2Helper

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
  end

  context 'unlicensed' do
    it 'does not show pull mirror settings', :js do
      stub_licensed_features(repository_mirrors: false)

      visit project_settings_repository_path(project)

      page.within('.project-mirror-settings') do
        expect(page).to have_selector('#url')
        expect(page).to have_selector('#mirror_direction')
        expect(page).to have_no_selector('#project_mirror', visible: false)
        expect(page).to have_no_selector('#project_mirror_user_id', visible: false)
        expect(page).to have_no_selector('#project_mirror_overwrites_diverged_branches')
        expect(page).to have_no_selector('#project_mirror_trigger_builds')
      end
    end
  end

  context 'licensed' do
    before do
      stub_licensed_features(repository_mirrors: true)
    end

    it 'shows pull mirror settings', :js do
      visit project_settings_repository_path(project)

      page.within('.project-mirror-settings') do
        expect(page).to have_selector('#url')
        expect(page).to have_selector('#mirror_direction')
        expect(page).to have_selector('#project_mirror', visible: false)
        expect(page).to have_selector('#project_mirror_user_id', visible: false)
        expect(page).to have_selector('#project_mirror_overwrites_diverged_branches')
        expect(page).to have_selector('#project_mirror_trigger_builds')
      end
    end

    context 'mirrored external repo', :js do
      let(:personal_access_token) { '461171575b95eeb61fba5face8ab838853d0121f' }
      let(:external_project) do
        create(:project_empty_repo,
               :mirror,
               import_url: "https://#{personal_access_token}@github.com/testngalog2/newrepository.git")
      end

      before do
        external_project.add_maintainer(user)
        visit project_settings_repository_path(external_project)
      end

      it 'does not show personal access token' do
        mirror_url = find('.mirror-url').text

        expect(mirror_url).not_to include(personal_access_token)
        expect(mirror_url).to include('https://*****@github.com/')
      end
    end
  end
end
