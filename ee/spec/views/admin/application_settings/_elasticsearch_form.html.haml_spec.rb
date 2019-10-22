# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/_elasticsearch_form' do
  set(:admin) { create(:admin) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:can?) { true }
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  context 'when elasticsearch_aws_secret_access_key is not set' do
    let(:application_setting) { build(:application_setting) }

    it 'does not set value of input field' do
      render
      expect(rendered).to have_field('AWS Secret Access Key', type: 'password')
    end
  end

  context 'when elasticsearch_aws_secret_access_key is set' do
    let(:application_setting) { build(:application_setting, elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key') }

    it 'sets value of input field to "true" instead of actual value' do
      render
      expect(rendered).to have_field('AWS Secret Access Key', type: 'password', with: 'true')
    end
  end
end
