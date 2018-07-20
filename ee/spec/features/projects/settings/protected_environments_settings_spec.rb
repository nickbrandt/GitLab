require 'spec_helper'

describe 'Projects > Settings > CI/CD > Protected Environments' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:environment) { create(:environment, project: project, name: 'production') }

  before do
    sign_in(user)
  end

  describe 'access' do
    before do
      project.add_role(user, role)

      visit project_settings_ci_cd_path(project)
    end

    context 'for developers' do
      let(:role) { :developer }

      it 'should be disallowed to view' do
        expect(page.status_code).to eq(404)
      end
    end

    context 'for maintainers' do
      let(:role) { :maintainer }

      it 'should be allowed to view' do
        visit project_settings_ci_cd_path(project)

        expect(page.status_code).to eq(200)
      end
    end
  end

  describe 'creating a protected environment' do
    before do
      project.add_maintainer(user)
      environment

      visit project_settings_ci_cd_path(project)
    end

    it 'should be allowed to create', :js do
      # Select environment
      find('.js-protected-environment-select').click
      within '.dropdown-menu-selectable' do
        find('.dropdown-input-field').set('production').native.send_keys(:enter)
      end

      # Select deploy access to developers and maintainers
      find('.js-allowed-to-deploy').click
      within '.deploy_access_levels-container' do
        find('a[data-role-id="30"]').click
      end

      click_on 'Protect'
      wait_for_requests

      expect(project.protected_environments.count).to eq(1)
    end
  end

  describe 'updating a protected environment' do
    let(:protected_environment) { create(:protected_environment, :developers_can_deploy, project: project, name: 'production') }

    before do
      project.add_maintainer(user)
      environment
      protected_environment

      visit project_settings_ci_cd_path(project)
    end

    it 'should be allowed to update', :js do
      within '.js-protected-environment-edit-form' do
        find('.js-allowed-to-deploy').click

        # Update deploy access to also allow maintainers
        within '.dropdown-menu-selectable' do
          find('a[data-role-id="40"]').click
        end
      end

      wait_for_requests
      expect(protected_environment.deploy_access_levels.count).to eq(2)
    end
  end
end
