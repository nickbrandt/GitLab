# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Error'] do
  specify { expect(described_class.graphql_name).to eq('Error') }

  it 'has the expected fields' do
    expected_fields = %w[
      message
      path
      extensions
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
