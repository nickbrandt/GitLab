# frozen_string_literal: true

require 'spec_helper'

# describe GitlabSchema.types['DesignAtVersion'] do
# This not available on the schema until we mount it somewhere
describe ::Types::DesignManagement::DesignAtVersionType.to_graphql do
  it_behaves_like 'a GraphQL type with design fields' do
    let(:extra_design_fields) { %i[version design] }
  end
end
