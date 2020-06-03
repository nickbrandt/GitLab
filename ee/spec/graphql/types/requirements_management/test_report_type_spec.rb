# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['TestReport'] do
  fields = %i[id state pipeline author created_at]

  it { expect(described_class.graphql_name).to eq('TestReport') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
