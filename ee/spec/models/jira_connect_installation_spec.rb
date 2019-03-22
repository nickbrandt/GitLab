# frozen_string_literal: true

require 'spec_helper'

describe JiraConnectInstallation do
  describe 'associations' do
    it { is_expected.to have_many(:subscriptions).class_name('JiraConnectSubscription') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:client_key) }
    it { is_expected.to validate_uniqueness_of(:client_key) }
    it { is_expected.to validate_presence_of(:shared_secret) }
    it { is_expected.to validate_presence_of(:base_url) }

    it { is_expected.to allow_value('https://test.atlassian.net').for(:base_url) }
    it { is_expected.not_to allow_value('not/a/url').for(:base_url) }
  end
end
