# frozen_string_literal: true

require 'spec_helper'

describe 'Admin updates EE-only settings' do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    allow(License).to receive(:feature_available?).and_return(true)
  end

  context 'Geo settings' do
    context 'when the license has Geo feature' do
      it 'allows users to change Geo settings' do
        visit geo_admin_application_settings_path
        page.within('.as-geo') do
          fill_in 'Connection timeout', with: 15
          fill_in 'Allowed Geo IP', with: '192.34.34.34'
          click_button 'Save changes'
        end

        expect(current_settings.geo_status_timeout).to eq(15)
        expect(current_settings.geo_node_allowed_ips).to eq('192.34.34.34')
        expect(page).to have_content 'Application settings saved successfully'
      end
    end

    context 'when the license does not have Geo feature' do
      it 'shows empty page' do
        allow(License).to receive(:feature_available?).and_return(false)

        visit geo_admin_application_settings_path

        expect(page).to have_content 'Discover GitLab Geo'
      end
    end
  end

  it 'Enables external authentication' do
    visit general_admin_application_settings_path
    page.within('.as-external-auth') do
      check 'Enable classification control using an external service'
      fill_in 'Default classification label', with: 'default'
      click_button 'Save changes'
    end

    expect(page).to have_content 'Application settings saved successfully'
  end

  it 'Enable Slack application' do
    visit integrations_admin_application_settings_path
    allow(Gitlab).to receive(:com?).and_return(true)
    visit integrations_admin_application_settings_path

    page.within('.as-slack') do
      check 'Enable Slack application'
      click_button 'Save changes'
    end

    expect(page).to have_content 'Application settings saved successfully'
  end

  context 'Templates page' do
    before do
      visit templates_admin_application_settings_path
    end

    it 'Render "Templates" section' do
      page.within('.as-visibility-access') do
        expect(page).to have_content 'Templates'
      end
    end

    it 'Render "Custom project templates" section' do
      page.within('.as-custom-project-templates') do
        expect(page).to have_content 'Custom project templates'
      end
    end
  end

  describe 'LDAP settings' do
    before do
      allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(ldap_setting)

      visit general_admin_application_settings_path
    end

    context 'with LDAP enabled' do
      let(:ldap_setting) { true }

      it 'Changes to allow group owners to manage ldap' do
        page.within('.as-visibility-access') do
          find('#application_setting_allow_group_owners_to_manage_ldap').set(false)
          click_button 'Save'
        end

        expect(page).to have_content('Application settings saved successfully')
        expect(find('#application_setting_allow_group_owners_to_manage_ldap')).not_to be_checked
      end
    end

    context 'with LDAP disabled' do
      let(:ldap_setting) { false }

      it 'Does not show option to allow group owners to manage ldap' do
        expect(page).not_to have_css('#application_setting_allow_group_owners_to_manage_ldap')
      end
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
