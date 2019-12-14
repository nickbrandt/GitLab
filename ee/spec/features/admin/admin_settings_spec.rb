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
        visit admin_geo_settings_path
        page.within('section') do
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

        visit admin_geo_settings_path

        expect(page).to have_content 'You need a different license to use Geo replication'
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

  context 'Elasticsearch settings' do
    before do
      visit integrations_admin_application_settings_path
      page.within('.as-elasticsearch') do
        click_button 'Expand'
      end
    end

    it 'changes elasticsearch settings' do
      page.within('.as-elasticsearch') do
        check 'Elasticsearch indexing'
        check 'Search with Elasticsearch enabled'
        fill_in 'Number of Elasticsearch shards', with: '120'
        fill_in 'Number of Elasticsearch replicas', with: '2'

        click_button 'Save changes'
      end

      aggregate_failures do
        expect(current_settings.elasticsearch_indexing).to be_truthy
        expect(current_settings.elasticsearch_search).to be_truthy
        expect(current_settings.elasticsearch_shards).to eq(120)
        expect(current_settings.elasticsearch_replicas).to eq(2)
        expect(page).to have_content 'Application settings saved successfully'
      end
    end

    it 'Allows limiting projects and namespaces to index', :aggregate_failures, :js do
      project = create(:project)
      namespace = create(:namespace)

      page.within('.as-elasticsearch') do
        expect(page).not_to have_content('Namespaces to index')
        expect(page).not_to have_content('Projects to index')

        check 'Limit namespaces and projects that can be indexed'

        expect(page).to have_content('Namespaces to index')
        expect(page).to have_content('Projects to index')

        fill_in 'Namespaces to index', with: namespace.name
        wait_for_requests
      end

      page.within('#select2-drop') do
        expect(page).to have_content(namespace.full_path)
      end

      page.within('.as-elasticsearch') do
        find('.js-limit-namespaces .select2-choices input[type=text]').native.send_keys(:enter)

        fill_in 'Projects to index', with: project.name
        wait_for_requests
      end

      page.within('#select2-drop') do
        expect(page).to have_content(project.full_name)
      end

      page.within('.as-elasticsearch') do
        find('.js-limit-projects .select2-choices input[type=text]').native.send_keys(:enter)

        click_button 'Save changes'
      end

      expect(current_settings.elasticsearch_limit_indexing).to be_truthy
      expect(ElasticsearchIndexedNamespace.exists?(namespace_id: namespace.id)).to be_truthy
      expect(ElasticsearchIndexedProject.exists?(project_id: project.id)).to be_truthy
    end

    it 'Allows removing all namespaces and projects', :aggregate_failures, :js do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)

      namespace = create(:elasticsearch_indexed_namespace).namespace
      project = create(:elasticsearch_indexed_project).project

      visit integrations_admin_application_settings_path

      expect(ElasticsearchIndexedNamespace.count).to be > 0
      expect(ElasticsearchIndexedProject.count).to be > 0

      page.within('.as-elasticsearch') do
        click_button 'Expand'

        expect(page).to have_content('Namespaces to index')
        expect(page).to have_content('Projects to index')
        expect(page).to have_content(namespace.full_name)
        expect(page).to have_content(project.full_name)

        find('.js-limit-namespaces .select2-search-choice-close').click
        find('.js-limit-projects .select2-search-choice-close').click

        expect(page).not_to have_content(namespace.full_name)
        expect(page).not_to have_content(project.full_name)

        click_button 'Save changes'
      end

      expect(ElasticsearchIndexedNamespace.count).to eq(0)
      expect(ElasticsearchIndexedProject.count).to eq(0)
      expect(page).to have_content 'Application settings saved successfully'
    end
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
