# frozen_string_literal: true

require 'spec_helper'

describe Types::PermissionTypes::Project do
  it "exposes design permissions" do
    expected_permissions = [
      :read_design, :create_design, :destroy_design
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
