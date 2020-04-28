# frozen_string_literal: true

require 'spec_helper'

describe 'getting a requirement list for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:requirement) { create(:requirement, project: project) }

  let(:requirements_data) { graphql_data['project']['requirements']['edges'] }
  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('requirements'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('requirements', {}, fields)
    )
  end

  context 'when user has access to the project' do
    before do
      stub_licensed_features(requirements: true)
      project.add_developer(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns requirements successfully' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_nil
      expect(requirements_data[0]['node']['id']).to eq requirement.to_global_id.to_s
    end

    context 'when limiting the number of results' do
      let(:query) do
        graphql_query_for(
          'project',
          { 'fullPath' => project.full_path },
          "requirements(first: 1) { #{fields} }"
        )
      end

      it_behaves_like 'a working graphql query' do
        before do
          post_graphql(query, current_user: current_user)
        end
      end
    end

    describe 'sorting and pagination' do
      let(:start_cursor) { graphql_data['project']['requirements']['pageInfo']['startCursor'] }
      let(:end_cursor) { graphql_data['project']['requirements']['pageInfo']['endCursor'] }

      def grab_iids(data = requirements_data)
        data.map do |requirement_hash|
          requirement_hash.dig('node', 'iid').to_i
        end
      end

      context 'when sorting by created_at' do
        let_it_be(:sort_project) { create(:project, :public) }
        let_it_be(:requirement1) { create(:requirement, project: sort_project, created_at: 3.days.from_now) }
        let_it_be(:requirement2) { create(:requirement, project: sort_project, created_at: 4.days.from_now) }
        let_it_be(:requirement3) { create(:requirement, project: sort_project, created_at: 2.days.ago) }
        let_it_be(:requirement4) { create(:requirement, project: sort_project, created_at: 5.days.ago) }
        let_it_be(:requirement5) { create(:requirement, project: sort_project, created_at: 1.day.ago) }

        let(:params) { 'sort: created_asc' }

        def query(requirement_params = params)
          graphql_query_for(
            'project',
            { 'fullPath' => sort_project.full_path },
            <<~REQUIREMENTS
            requirements(#{requirement_params}) {
              pageInfo {
                endCursor
              }
              edges {
                node {
                  iid
                  createdAt
                }
              }
            }
            REQUIREMENTS
          )
        end

        def post_query_with_after_cursor(sort_by)
          cursored_query = query("sort: #{sort_by}, after: \"#{end_cursor}\"")
          post_graphql(cursored_query, current_user: current_user)

          Gitlab::Json.parse(response.body)['data']['project']['requirements']['edges']
        end

        before do
          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query'

        context 'when ascending' do
          it 'sorts requirements' do
            expect(grab_iids).to eq [requirement4.iid, requirement3.iid, requirement5.iid, requirement1.iid, requirement2.iid]
          end

          context 'when paginating' do
            let(:params) { 'sort: created_asc, first: 2' }

            it 'sorts requirements' do
              expect(grab_iids).to eq [requirement4.iid, requirement3.iid]

              response_data = post_query_with_after_cursor('created_asc')

              expect(grab_iids(response_data)).to eq [requirement5.iid, requirement1.iid, requirement2.iid]
            end
          end
        end

        context 'when descending' do
          let(:params) { 'sort: created_desc' }

          it 'sorts requirements' do
            expect(grab_iids).to eq [requirement2.iid, requirement1.iid, requirement5.iid, requirement3.iid, requirement4.iid]
          end

          context 'when paginating' do
            let(:params) { 'sort: created_desc, first: 2' }

            it 'sorts requirements' do
              expect(grab_iids).to eq [requirement2.iid, requirement1.iid]

              response_data = post_query_with_after_cursor('created_desc')

              expect(grab_iids(response_data)).to eq [requirement5.iid, requirement3.iid, requirement4.iid]
            end
          end
        end
      end
    end
  end

  context 'when the user does not have access to the requirement' do
    before do
      stub_licensed_features(requirements: true)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end

  context 'when requirements feature is not available' do
    before do
      stub_licensed_features(requirements: false)
      project.add_developer(current_user)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end
end
