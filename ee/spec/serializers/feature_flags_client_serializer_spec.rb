# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagsClientSerializer do
  let(:project) { create(:project) }
  let(:feature_flags_client) { project.create_operations_feature_flags_client! }
  let(:serializer) { described_class.new }

  before do
    stub_licensed_features(feature_flags: true)
  end

  describe '#represent_token' do
    subject { serializer.represent_token(feature_flags_client).to_json }

    it 'includes feature flags client token' do
      expect(subject).to match_schema('feature_flags_client_token', dir: 'ee')
    end
  end
end
