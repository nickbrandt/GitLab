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
          click_button 'Save changes'
        end

        expect(Gitlab::CurrentSettings.geo_status_timeout).to eq(15)
        expect(page).to have_content "Application settings saved successfully"
      end
    end

    context 'when the license does not have Geo feature' do
      it 'shows empty page' do
        allow(License).to receive(:feature_available?).and_return(false)

        visit geo_admin_application_settings_path

        expect(page).to have_content "Discover GitLab Geo"
      end
    end
  end

  it 'Enable external authentication' do
    visit admin_application_settings_path
    page.within('.as-external-auth') do
      check 'Enable classification control using an external service'
      fill_in 'Default classification label', with: 'default'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  context 'Elasticsearch settings' do
    before do
      visit integrations_admin_application_settings_path
    end

    it 'Enable elastic search indexing' do
      page.within('.as-elasticsearch') do
        check 'Elasticsearch indexing'
        click_button 'Save changes'
      end

      expect(Gitlab::CurrentSettings.elasticsearch_indexing).to be_truthy
      expect(page).to have_content "Application settings saved successfully"
    end

    it 'Allows limiting projects and namespaces to index', :js do
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

      expect(Gitlab::CurrentSettings.elasticsearch_limit_indexing).to be_truthy
      expect(ElasticsearchIndexedNamespace.exists?(namespace_id: namespace.id)).to be_truthy
      expect(ElasticsearchIndexedProject.exists?(project_id: project.id)).to be_truthy
      expect(page).to have_content "Application settings saved successfully"
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

    expect(page).to have_content "Application settings saved successfully"
  end

  context 'Templates page' do
    before do
      visit templates_admin_application_settings_path
    end

    it 'Render "Templates" section' do
      page.within('.as-visibility-access') do
        expect(page).to have_content "Templates"
      end
    end

    it 'Render "Custom project templates" section' do
      page.within('.as-custom-project-templates') do
        expect(page).to have_content "Custom project templates"
      end
    end
  end
end
