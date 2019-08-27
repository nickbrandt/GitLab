# frozen_string_literal: true

require 'spec_helper'

describe 'Admin updates Elasticsearch settings' do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    allow(License).to receive(:feature_available?).and_return(true)
  end

  context 'global settings' do
    before do
      visit admin_elasticsearch_settings_path
    end

    it 'changes elasticsearch settings' do
      page.within('#content-body.content') do
        check 'Advanced Global Search enabled'

        click_button 'Save changes'
      end

      aggregate_failures do
        expect(current_settings.elasticsearch_search).to be_truthy
        expect(page).to have_content 'Application settings saved successfully'
      end
    end

    it 'allows limiting projects and namespaces to index', :js do
      project = create(:project)
      namespace = create(:namespace)

      page.within('#content-body.content') do
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

      page.within('#content-body.content') do
        find('.js-limit-namespaces .select2-choices input[type=text]').native.send_keys(:enter)

        fill_in 'Projects to index', with: project.name
        wait_for_requests
      end

      page.within('#select2-drop') do
        expect(page).to have_content(project.full_name)
      end

      page.within('#content-body.content') do
        find('.js-limit-projects .select2-choices input[type=text]').native.send_keys(:enter)

        click_button 'Save changes'
      end

      wait_for_all_requests

      expect(current_settings.elasticsearch_limit_indexing).to be_truthy
      expect(ElasticsearchIndexedNamespace.exists?(namespace_id: namespace.id)).to be_truthy
      expect(ElasticsearchIndexedProject.exists?(project_id: project.id)).to be_truthy
      expect(page).to have_content 'Application settings saved successfully'
    end

    it 'allows removing all namespaces and projects', :js do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)

      namespace = create(:elasticsearch_indexed_namespace).namespace
      project = create(:elasticsearch_indexed_project).project

      visit admin_elasticsearch_settings_path

      expect(ElasticsearchIndexedNamespace.count).to be > 0
      expect(ElasticsearchIndexedProject.count).to be > 0

      page.within('#content-body.content') do
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

  context 'index settings' do
    before do
      visit admin_elasticsearch_root_path
    end

    it 'changes elasticsearch settings' do
      page.within('#content-body.content') do
        check 'Elasticsearch indexing'
        fill_in 'Number of Elasticsearch shards', with: '120'
        fill_in 'Number of Elasticsearch replicas', with: '2'

        click_button 'Save changes'
      end

      aggregate_failures do
        expect(current_settings.elasticsearch_indexing).to eq(true)
        expect(current_settings.elasticsearch_shards).to eq(120)
        expect(current_settings.elasticsearch_replicas).to eq(2)
        expect(page).to have_content 'Application settings saved successfully'
      end
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
