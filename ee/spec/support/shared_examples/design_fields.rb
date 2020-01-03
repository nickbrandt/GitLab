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

    it 'resolves to the design image URL' do
      image = field.resolve(instance, args, context).value
      sha = design.versions.first.sha
      url = ::Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)

      expect(image).to eq(url)
    end

    it 'has better than O(N) peformance' do
      baseline = ActiveRecord::QueryRecorder.new { field.resolve(instance, args, context).value }
      baseline.count

      expect do
        image_a = field.resolve(instance, args, context)
        image_b = field.resolve(instance, args, context)
        expect(image_a.value).to eq(image_b.value)
      end.not_to exceed_query_limit(baseline)
    end
  end
end
