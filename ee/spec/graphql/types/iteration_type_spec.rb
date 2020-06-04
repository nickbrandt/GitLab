# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Iteration'] do
  it { expect(described_class.graphql_name).to eq('Iteration') }

  it { expect(described_class).to require_graphql_authorizations(:read_iteration) }
end
