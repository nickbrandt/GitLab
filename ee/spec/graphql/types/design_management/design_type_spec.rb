# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Design'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it { expect(described_class.interfaces).to include(Types::Notes::NoteableType.to_graphql) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      project
      issue
      filename
      image
      versions
      discussions
      notes
      diff_refs
      full_path
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
