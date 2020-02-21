# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/_elasticsearch_form' do
  let_it_be(:admin) { create(:admin) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  context 'es index dependent' do
    before do
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_indexing?)).and_return(es_indexing)
      allow(Gitlab::Elastic::Helper).to(receive(:index_exists?)).and_return(index_exists)
    end

    let(:warning_msg) { 'create an index before enabling indexing' }
    let(:button_text) { 'Index all projects' }
    let(:application_setting) { build(:application_setting, elasticsearch_indexing: es_indexing) }

    context 'when elasticsearch index does not exist with indexing enabled' do
      let(:es_indexing) { true }
      let(:index_exists) { false }

      it 'shows a warning and disables a button' do
        render

        expect(rendered).to have_content(warning_msg)
        expect(rendered).to have_css('a.btn-success.disabled', text: button_text)
        expect(rendered).to have_css('#application_setting_elasticsearch_indexing')
        expect(rendered).not_to have_css('#application_setting_elasticsearch_indexing[disabled="disabled"]')
      end
    end

    context 'when elasticsearch index does not exist with indexing disabled' do
      let(:es_indexing) { false }
      let(:index_exists) { false }

      it 'shows a warning and disables a checkbox and hides an indexing button' do
        render

        expect(rendered).to have_content(warning_msg)
        expect(rendered).not_to have_css('a.btn-success', text: button_text)
        expect(rendered).to have_css('#application_setting_elasticsearch_indexing[disabled="disabled"]')
      end
    end

    context 'when elasticsearch index exists' do
      let(:es_indexing) { true }
      let(:index_exists) { true }

      it 'shows non-disabled index button without a warning' do
        render

        expect(rendered).to have_css('a.btn-success', text: button_text)
        expect(rendered).not_to have_css('a.btn-success.disabled', text: button_text)
        expect(rendered).not_to have_content(warning_msg)
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
