# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::CiConfiguration::DependencyScanning::InputType do
  it { expect(described_class.graphql_name).to eq('DependencyScanningCiConfigurationInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[global pipeline analyzers]) }
end
