# frozen_string_literal: true

require 'spec_helper'

describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:current_user) { create(:user) }
  let(:issues_data) { graphql_data['project']['issues']['edges'] }

  describe 'sorting and pagination' do
    let(:start_cursor) { graphql_data['project']['issues']['pageInfo']['startCursor'] }
    let(:end_cursor) { graphql_data['project']['issues']['pageInfo']['endCursor'] }

    context 'when sorting by weight' do
      let(:sort_project) { create(:project, :public) }

      let!(:weight_issue1) { create(:issue, project: sort_project, weight: 5) }
      let!(:weight_issue2) { create(:issue, project: sort_project, weight: nil) }
      let!(:weight_issue3) { create(:issue, project: sort_project, weight: 1) }
      let!(:weight_issue4) { create(:issue, project: sort_project, weight: nil) }
      let!(:weight_issue5) { create(:issue, project: sort_project, weight: 3) }

      let(:params) { 'sort: WEIGHT_ASC' }

      def query(issue_params = params)
        graphql_query_for(
          'project',
          { 'fullPath' => sort_project.full_path },
          <<~ISSUES
          issues(#{issue_params}) {
            pageInfo {
              endCursor
            }
            edges {
              node {
                iid
                weight
              }
            }
          }
        ISSUES
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      context 'when ascending' do
        it 'sorts issues' do
          expect(grab_iids).to eq [weight_issue3.iid, weight_issue5.iid, weight_issue1.iid, weight_issue4.iid, weight_issue2.iid]
        end

        context 'when paginating' do
          let(:params) { 'sort: WEIGHT_ASC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq [weight_issue3.iid, weight_issue5.iid]

            cursored_query = query("sort: WEIGHT_ASC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq [weight_issue1.iid, weight_issue4.iid, weight_issue2.iid]
          end
        end
      end

      context 'when descending' do
        let(:params) { 'sort: WEIGHT_DESC' }

        it 'sorts issues' do
          expect(grab_iids).to eq [weight_issue1.iid, weight_issue5.iid, weight_issue3.iid, weight_issue4.iid, weight_issue2.iid]
        end

        context 'when paginating' do
          let(:params) { 'sort: WEIGHT_DESC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq [weight_issue1.iid, weight_issue5.iid]

            cursored_query = query("sort: WEIGHT_DESC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq [weight_issue3.iid, weight_issue4.iid, weight_issue2.iid]
          end
        end
      end
    end
  end

  def grab_iids(data = issues_data)
    data.map do |issue|
      issue.dig('node', 'iid').to_i
    end
  end
end
