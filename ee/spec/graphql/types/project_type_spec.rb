# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Project'] do
  it 'includes the ee specific fields' do
    expected_fields = %w[service_desk_enabled service_desk_address]

    is_expected.to include_graphql_fields(*expected_fields)
  end
end
