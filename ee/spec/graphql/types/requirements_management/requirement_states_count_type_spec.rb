# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RequirementStatesCount'] do
  it { expect(described_class.graphql_name).to eq('RequirementStatesCount') }

  it 'has specific fields' do
    %i[opened closed].each do |field_name|
      expect(described_class).to have_graphql_field(field_name)
    end
  end

  # remove this in %14.6
  it 'has deprecated field `archived` as an alias' do
    expect(described_class).to have_graphql_field(:archived)
  end
end
