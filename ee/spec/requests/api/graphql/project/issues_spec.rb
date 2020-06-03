# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  describe 'sorting and pagination' do
    let(:sort_project) { create(:project, :public) }
    let(:data_path)    { [:project, :issues] }

    def pagination_query(params, page_info)
      graphql_query_for(
        'project',
        { 'fullPath' => sort_project.full_path },
        "issues(#{params}) { #{page_info} edges { node { iid weight } } }"
      )
    end

    def pagination_results_data(data)
      data.map { |issue| issue.dig('node', 'iid').to_i }
    end

    context 'when sorting by weight' do
      let!(:weight_issue1) { create(:issue, project: sort_project, weight: 5) }
      let!(:weight_issue2) { create(:issue, project: sort_project, weight: nil) }
      let!(:weight_issue3) { create(:issue, project: sort_project, weight: 1) }
      let!(:weight_issue4) { create(:issue, project: sort_project, weight: nil) }
      let!(:weight_issue5) { create(:issue, project: sort_project, weight: 3) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'WEIGHT_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [weight_issue3.iid, weight_issue5.iid, weight_issue1.iid, weight_issue4.iid, weight_issue2.iid] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'WEIGHT_DESC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [weight_issue1.iid, weight_issue5.iid, weight_issue3.iid, weight_issue4.iid, weight_issue2.iid] }
        end
      end
    end
  end
end
