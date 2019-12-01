# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/_elasticsearch_form' do
  set(:admin) { create(:admin) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
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
end
