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

  describe '#image' do
    let(:schema) { GitlabSchema }
    let(:query) { GraphQL::Query.new(schema) }
    let(:context) { double('Context', schema: schema, query: query, parent: nil) }
    let(:field) { described_class.fields['image'] }
    let(:args) { GraphQL::Query::Arguments::NO_ARGS }
    let(:instance) { object_type.authorized_new(object, query.context) }
    let(:instance_b) { object_type.authorized_new(object_b, query.context) }

    it 'resolves to the design image URL' do
      image = field.resolve(instance, args, context).value
      sha = design.versions.first.sha
      url = ::Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)

      expect(image).to eq(url)
    end

    it 'has better than O(N) peformance', :request_store do
      # One query each for:
      #  - design_management_versions x each version
      #    (Request store is needed so that version is fetched only once.)
      #  - projects
      #    - routes
      #    - namespaces
      #      - routes
      # So no. of queries is linear in number of versions, with constant
      # overhead of 4 queries - here summing to 2 + 4 = 6
      expect do
        image_a = field.resolve(instance, args, context)
        image_b = field.resolve(instance, args, context)
        image_c = field.resolve(instance_b, args, context)
        expect(image_a.value).to eq(image_b.value)
        expect(image_c.value).not_to eq('')
      end.not_to exceed_query_limit(6)
    end
  end
end
