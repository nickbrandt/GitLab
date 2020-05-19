# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Member'] do
  specify { expect(described_class.graphql_name).to eq('Member') }

  it 'has the expected fields' do
    expected_fields = %w[
      access_level source_type created_by created_at updated_at expires_at source
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'created_by field' do
    subject { described_class.fields['createdBy'] }

    it 'has a UserType type' do
      is_expected.to have_graphql_type(Types::UserType)
    end
  end
end
