# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::CiConfiguration::DependencyScanning::EntityInputType do
  it { expect(described_class.graphql_name).to eq('DependencyScanningCiConfigurationEntityInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[field defaultValue value]) }
end
