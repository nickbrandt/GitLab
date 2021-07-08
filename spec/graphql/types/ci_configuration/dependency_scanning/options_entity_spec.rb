# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyScanningCiConfigurationOptionsEntity'] do
  let(:fields) { %i[label value] }

  it { expect(described_class.graphql_name).to eq('DependencyScanningCiConfigurationOptionsEntity') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
