# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagsHelper do
  let_it_be(:project) { create(:project) }

  describe '#unleash_api_url' do
    subject { helper.unleash_api_url(project) }

    it { is_expected.to end_with("/api/v4/feature_flags/unleash/#{project.id}") }
  end

  describe '#unleash_api_instance_id' do
    subject { helper.unleash_api_instance_id(project) }

    it { is_expected.not_to be_empty }
  end
end
