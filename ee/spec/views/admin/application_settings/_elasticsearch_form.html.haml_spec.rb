# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_elasticsearch_form' do
  let_it_be(:admin) { create(:admin) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  context 'es indexing' do
    let(:application_setting) { build(:application_setting) }
    let(:button_text) { 'Index all projects' }

    before do
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_indexing?)).and_return(es_indexing)
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_pause_indexing?)).and_return(true)
    end

    context 'indexing is enabled' do
      let(:es_indexing) { true }

      it 'hides index button when indexing is disabled' do
        render

        expect(rendered).to have_css('a.btn-success', text: button_text)
      end

      it 'renders an enabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing]')
        expect(rendered).not_to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end
    end

    context 'indexing is disabled' do
      let(:es_indexing) { false }

      it 'shows index button when indexing is enabled' do
        render

        expect(rendered).not_to have_css('a.btn-success', text: button_text)
      end

      it 'renders a disabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end
    end
  end

  context 'when elasticsearch_aws_secret_access_key is not set' do
    let(:application_setting) { build(:application_setting) }

    it 'has field with "AWS Secret Access Key" label and no value' do
      render
      expect(rendered).to have_field('AWS Secret Access Key', type: 'password')
      expect(page.find_field('AWS Secret Access Key').value).to be_blank
    end
  end

  context 'when elasticsearch_aws_secret_access_key is set' do
    let(:application_setting) { build(:application_setting, elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key') }

    it 'has field with "Enter new AWS Secret Access Key" label and no value' do
      render
      expect(rendered).to have_field('Enter new AWS Secret Access Key', type: 'password')
      expect(page.find_field('Enter new AWS Secret Access Key').value).to be_blank
    end
  end

  context 'when there are elasticsearch indexed namespaces' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_field('application_setting[elasticsearch_namespace_ids]')
    end

    context 'when there are too many elasticsearch indexed namespaces' do
      before do
        create_list :elasticsearch_indexed_namespace, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_field('application_setting[elasticsearch_namespace_ids]')
      end
    end
  end

  context 'when there are elasticsearch indexed projects' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_field('application_setting[elasticsearch_project_ids]')
    end

    context 'when there are too many elasticsearch indexed projects' do
      before do
        create_list :elasticsearch_indexed_project, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_field('application_setting[elasticsearch_project_ids]')
      end
    end
  end
end
