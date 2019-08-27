# frozen_string_literal: true

require 'spec_helper'

describe "Getting designs related to an issue" do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let(:design) { create(:design, :with_file, versions_count: 1) }
  let(:current_user) { design.project.owner }
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
  let(:query) do
    graphql_query_for(
      "project",
      { "fullPath" => design.project.full_path },
      query_graphql_field(
        "issue",
        { iid: design.issue.iid },
        query_graphql_field(
          "designs", {}, design_query
        )
      )
    )
  end
  let(:design_collection) do
    graphql_data["project"]["issue"]["designs"]
  end
  let(:design_response) do
    design_collection["designs"]["edges"].first["node"]
  end

  context "when the feature is not available" do
    before do
      stub_licensed_features(design_management: false)
      stub_feature_flags(design_managment: false)
    end

    it_behaves_like "a working graphql query" do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it "returns no designs" do
      post_graphql(query, current_user: current_user)

      expect(design_collection).to be_nil
    end
  end

  context "when the feature is available" do
    before do
      enable_design_management
    end

    it "returns the design filename" do
      post_graphql(query, current_user: current_user)

      expect(design_response["filename"]).to eq(design.filename)
    end

    context "with versions" do
      let(:version) { design.versions.take }
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

      it "includes the version id" do
        post_graphql(query, current_user: current_user)

        version_id = design_response["versions"]["edges"].first["node"]["id"]

        expect(version_id).to eq(version.to_global_id.to_s)
      end

      it "includes the version sha" do
        post_graphql(query, current_user: current_user)

        version_sha = design_response["versions"]["edges"].first["node"]["sha"]

        expect(version_sha).to eq(version.sha)
      end
    end

    describe "viewing a design board at a particular version" do
      let(:issue) { design.issue }
      let(:all_versions) { issue.design_collection.versions.ordered }
      let!(:second_design) { create(:design, :with_file, issue: issue, versions_count: 1) }
      let(:design_query) do
        <<~NODE
        designs(atVersion: "#{version.to_global_id}") {
          edges {
            node {
              image
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
        design_collection["designs"]["edges"]
      end

      def image_url(design, sha = nil)
        Gitlab::Routing.url_helpers.project_design_url(design.project, design, sha)
      end

      def version_global_id(version)
        version.to_global_id.to_s
      end

      # Filters just design nodes from the larger `design_response`
      def design_nodes
        design_response.each do |response|
          response['node'].delete('versions')
        end
      end

      # Filters just version nodes from the larger `design_response`
      def version_nodes
        design_response.map do |response|
          response.dig('node', 'versions', 'edges')
        end
      end

      context "viewing the original version" do
        let(:version) { all_versions.last }

        it "only returns the first design, with the correct version of the design image" do
          post_graphql(query, current_user: current_user)

          expect(design_nodes).to eql(
            [{ "node" => { "image" => image_url(design, version.sha) } }]
          )
        end

        it "only returns one version record for the design (the original version)" do
          post_graphql(query, current_user: current_user)

          expect(version_nodes).to eq(
            [
              [{ "node" => { "id" => version_global_id(version) } }]
            ]
          )
        end
      end

      context "viewing the newest version" do
        let(:version) { all_versions.first }

        it "returns both designs, with the correct version of the design images" do
          post_graphql(query, current_user: current_user)

          expect(design_nodes).to eq(
            [
              { "node" => { "image" => image_url(design, version.sha) } },
              { "node" => { "image" => image_url(second_design, version.sha) } }
            ]
          )
        end

        it "returns the correct versions records for both designs" do
          post_graphql(query, current_user: current_user)

          expect(version_nodes).to eq(
            [
              [{ "node" => { "id" => version_global_id(design.versions.first) } }],
              [{ "node" => { "id" => version_global_id(second_design.versions.first) } }]
            ]
          )
        end
      end
    end

    describe 'a design with note annotations' do
      let!(:note) { create(:diff_note_on_design, noteable: design, project: design.project) }

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
        design_collection["designs"]["edges"].first["node"]
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it 'returns the notes for the design' do
        expect(design_response.dig("notes", "edges")).to eq(
          ["node" => { "id" => note.to_global_id.to_s }]
        )
      end

      it 'returns a note_count for the design' do
        expect(design_response["notesCount"]).to eq(1)
      end
    end
  end
end
