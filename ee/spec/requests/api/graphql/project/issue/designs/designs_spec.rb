# frozen_string_literal: true

require 'spec_helper'

describe 'Getting designs related to an issue' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:design) { create(:design, :with_file, versions_count: 1) }
  let_it_be(:current_user) { design.project.owner }
  let(:design_query) do
    <<~NODE
    designs {
      edges {
        node {
          filename
        }
      }
    }
    NODE
  end

  let(:issue) { design.issue }
  let(:project) { issue.project }

  let(:query) { make_query }

  def make_query(dq = design_query)
    designs_field = query_graphql_field(:design_collection, {}, dq)
    issue_field = query_graphql_field(:issue, { iid: issue.iid.to_s }, designs_field)

    graphql_query_for(:project, { fullPath: project.full_path }, issue_field)
  end

  let(:design_collection) do
    graphql_data_at(:project, :issue, :design_collection)
  end

  let(:design_response) do
    design_collection.dig('designs', 'edges').first['node']
  end

  context 'when the feature is not available' do
    before do
      stub_licensed_features(design_management: false)
      stub_feature_flags(design_managment: false)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns no designs' do
      post_graphql(query, current_user: current_user)

      expect(design_collection).to be_nil
    end
  end

  context 'when the feature is available' do
    before do
      enable_design_management
    end

    it 'returns the design filename' do
      post_graphql(query, current_user: current_user)

      expect(design_response['filename']).to eq(design.filename)
    end

    describe 'pagination' do
      before do
        create_list(:design, 5, :with_file, issue: issue)
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      let(:issue) { create(:issue) }

      let(:end_cursor) { design_collection.dig('designs', 'pageInfo', 'endCursor') }

      let(:ids) { issue.designs.order(:id).map { |d| global_id_of(d) } }

      let(:query) { make_query(designs_fragment(first: 2)) }

      let(:design_query_fields) { 'pageInfo { endCursor } edges { node { id } }' }

      let(:cursored_query) do
        make_query(designs_fragment(after: end_cursor))
      end

      def designs_fragment(params)
        query_graphql_field(:designs, params, design_query_fields)
      end

      def response_ids(data = graphql_data)
        path = %w[project issue designCollection designs edges]
        data.dig(*path).map { |e| e.dig('node', 'id') }
      end

      it 'sorts designs for reliable pagination' do
        expect(response_ids).to match_array(ids.take(2))

        post_graphql(cursored_query, current_user: current_user)

        new_data = JSON.parse(response.body).fetch('data')

        expect(response_ids(new_data)).to match_array(ids.drop(2))
      end
    end

    context 'with versions' do
      let_it_be(:version) { design.versions.take }
      let(:design_query) do
        <<~NODE
        designs {
          edges {
            node {
              filename
              versions {
                edges {
                  node {
                    id
                    sha
                  }
                }
              }
            }
          }
        }
        NODE
      end

      it 'includes the version id' do
        post_graphql(query, current_user: current_user)

        version_id = design_response['versions']['edges'].first['node']['id']

        expect(version_id).to eq(version.to_global_id.to_s)
      end

      it 'includes the version sha' do
        post_graphql(query, current_user: current_user)

        version_sha = design_response['versions']['edges'].first['node']['sha']

        expect(version_sha).to eq(version.sha)
      end
    end

    describe 'viewing a design board at a particular version' do
      let_it_be(:issue) { design.issue }
      let_it_be(:second_design) { create(:design, :with_file, issue: issue, versions_count: 1) }
      let_it_be(:deleted_design) { create(:design, :with_versions, issue: issue, deleted: true, versions_count: 1) }
      let(:all_versions) { issue.design_versions.ordered.reverse }
      let(:design_query) do
        <<~NODE
        designs(atVersion: "#{version.to_global_id}") {
          edges {
            node {
              id
              image
              event
              versions {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          }
        }
        NODE
      end
      let(:design_response) do
        design_collection['designs']['edges']
      end

      def image_url(design, sha = nil)
        Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)
      end

      def global_id(object)
        object.to_global_id.to_s
      end

      # Filters just design nodes from the larger `design_response`
      def design_nodes
        design_response.map do |response|
          response['node']
        end
      end

      # Filters just version nodes from the larger `design_response`
      def version_nodes
        design_response.map do |response|
          response.dig('node', 'versions', 'edges')
        end
      end

      context 'viewing the original version, when one design was created' do
        let(:version) { all_versions.first }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'only returns the first design' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design))
          )
        end

        it 'returns the correct version of the design image' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => image_url(design, version.sha))
          )
        end

        it 'returns the correct event for the design in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'CREATION')
          )
        end

        it 'only returns one version record for the design (the original version)' do
          expect(version_nodes).to eq([
            [{ 'node' => { 'id' => global_id(version) } }]
          ])
        end
      end

      context 'viewing the second version, when one design was created' do
        let(:version) { all_versions.second }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'only returns the first two designs' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design)),
            a_hash_including('id' => global_id(second_design))
          )
        end

        it 'returns the correct versions of the design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => image_url(design, version.sha)),
            a_hash_including('image' => image_url(second_design, version.sha))
          )
        end

        it 'returns the correct events for the designs in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'NONE'),
            a_hash_including('event' => 'CREATION')
          )
        end

        it 'returns the correct versions records for both designs' do
          expect(version_nodes).to eq([
            [{ 'node' => { 'id' => global_id(design.versions.first) } }],
            [{ 'node' => { 'id' => global_id(second_design.versions.first) } }]
          ])
        end
      end

      context 'viewing the last version, when one design was deleted and one was updated' do
        let(:version) { all_versions.last }

        before do
          second_design.actions.create!(version: version, event: 'modification')

          post_graphql(query, current_user: current_user)
        end

        it 'does not include the deleted design' do
          # The design does exist in the version
          expect(version.designs).to include(deleted_design)

          # But the GraphQL API does not include it in these results
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design)),
            a_hash_including('id' => global_id(second_design))
          )
        end

        it 'returns the correct versions of the design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => image_url(design, version.sha)),
            a_hash_including('image' => image_url(second_design, version.sha))
          )
        end

        it 'returns the correct events for the designs in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'NONE'),
            a_hash_including('event' => 'MODIFICATION')
          )
        end

        it 'returns all versions records for the designs' do
          expect(version_nodes).to eq([
            [
              { 'node' => { 'id' => global_id(design.versions.first) } }
            ],
            [
              { 'node' => { 'id' => global_id(second_design.versions.second) } },
              { 'node' => { 'id' => global_id(second_design.versions.first) } }
            ]
          ])
        end
      end
    end

    describe 'a design with note annotations' do
      let_it_be(:note) { create(:diff_note_on_design, noteable: design, project: design.project) }

      let(:design_query) do
        <<~NODE
        designs {
          edges {
            node {
              notesCount
              notes {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          }
        }
        NODE
      end

      let(:design_response) do
        design_collection['designs']['edges'].first['node']
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it 'returns the notes for the design' do
        expect(design_response.dig('notes', 'edges')).to eq(
          ['node' => { 'id' => note.to_global_id.to_s }]
        )
      end

      it 'returns a note_count for the design' do
        expect(design_response['notesCount']).to eq(1)
      end
    end
  end
end
