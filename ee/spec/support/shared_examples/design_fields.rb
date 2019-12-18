# frozen_string_literal: true

# To use these shared examples, you may define a value in scope named
# `extra_design_fields`, to pass any extra fields in addition to the
# standard design fields.
shared_examples 'a GraphQL type with design fields' do
  let(:extra_design_fields) { [] }

  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it 'exposes the expected design fields' do
    expected_fields = %i[
      id
      project
      issue
      filename
      full_path
      image
      diff_refs
      event
      notes_count
    ] + extra_design_fields

    is_expected.to have_graphql_fields(*expected_fields).only
  end
end
