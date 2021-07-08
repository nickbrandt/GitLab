# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyScanningCiConfigurationEntity'] do
  let(:fields) { %i[field label description type options default_value value size] }

  it { expect(described_class.graphql_name).to eq('DependencyScanningCiConfigurationEntity') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
