# frozen_string_literal: true

require 'spec_helper'

describe 'get board lists' do
  include GraphqlHelpers

  let_it_be(:user)               { create(:user) }
  let_it_be(:project)            { create(:project, creator_id: user.id, namespace: user.namespace ) }
  let_it_be(:group)              { create(:group, :private) }
  let_it_be(:project_milestone)  { create(:milestone, project: project) }
  let_it_be(:project_milestone2) { create(:milestone, project: project) }
  let_it_be(:group_milestone)    { create(:milestone, group: group) }
  let_it_be(:group_milestone2)   { create(:milestone, group: group) }
  let_it_be(:assignee)           { create(:assignee) }
  let_it_be(:assignee2)          { create(:assignee) }

  let(:params)            { '' }
  let(:board)             { }
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:board_data)        { graphql_data[board_parent_type]['boards']['edges'].first['node'] }
  let(:lists_data)        { board_data['lists']['edges'] }
  let(:start_cursor)      { board_data['lists']['pageInfo']['startCursor'] }
  let(:end_cursor)        { board_data['lists']['pageInfo']['endCursor'] }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
  end

  def query(list_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
      boards(first: 1) {
        edges {
          node {
            #{field_with_params('lists', list_params)} {
              pageInfo {
                startCursor
                endCursor
              }
              edges {
                node {
                  #{all_graphql_fields_for('board_lists'.classify)}
                }
              }
            }
          }
        }
      }
    BOARDS
    )
  end

  shared_examples 'group and project board lists query' do
    let!(:board) { create(:board, resource_parent: board_parent) }

    context 'when user can read the board' do
      before do
        board_parent.add_reporter(user)
      end

      describe 'sorting and pagination' do
        context 'when using default sorting' do
          let!(:milestone_list)  { create(:milestone_list, board: board, milestone: milestone, position: 10) }
          let!(:milestone_list2) { create(:milestone_list, board: board, milestone: milestone2, position: 2) }
          let!(:assignee_list)   { create(:user_list, board: board, user: assignee, position: 5) }
          let!(:assignee_list2)  { create(:user_list, board: board, user: assignee2, position: 1) }
          let(:closed_list)      { board.lists.find_by(list_type: :closed) }

          before do
            post_graphql(query, current_user: user)
          end

          it_behaves_like 'a working graphql query'

          context 'when ascending' do
            let(:lists) { [closed_list, assignee_list2, assignee_list, milestone_list2, milestone_list] }
            let(:expected_list_gids) do
              lists.map { |list| list.to_global_id.to_s }
            end

            it 'sorts lists' do
              expect(grab_ids).to eq expected_list_gids
            end

            context 'when paginating' do
              let(:params) { 'first: 2' }

              it 'sorts boards' do
                expect(grab_ids).to eq expected_list_gids.first(2)

                cursored_query = query("after: \"#{end_cursor}\"")
                post_graphql(cursored_query, current_user: user)

                response_data = grab_list_data(response.body)

                expect(grab_ids(response_data)).to eq expected_list_gids.drop(2).first(3)
              end
            end
          end
        end
      end

      describe 'limit metric settings' do
        let(:limit_metric_params) { { limit_metric: 'issue_count', max_issue_count: 10, max_issue_weight: 4 } }
        let!(:list_with_limit_metrics) { create(:list, board: board, **limit_metric_params) }

        before do
          post_graphql(query, current_user: user)
        end

        it 'returns the expected limit metric settings' do
          lists = grab_list_data(response.body).map { |item| item['node'] }

          list = lists.find { |l| l['id'] == list_with_limit_metrics.to_global_id.to_s }

          expect(list['limitMetric']).to eq('issue_count')
          expect(list['maxIssueCount']).to eq(10)
          expect(list['maxIssueWeight']).to eq(4)
        end
      end
    end
  end

  describe 'for a project' do
    let(:board_parent) { project }
    let(:milestone)    { project_milestone }
    let(:milestone2)   { project_milestone2 }

    it_behaves_like 'group and project board lists query'
  end

  describe 'for a group' do
    let(:board_parent) { group }
    let(:milestone)    { group_milestone }
    let(:milestone2)   { group_milestone2 }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project board lists query'
  end

  def grab_ids(data = lists_data)
    data.map { |list| list.dig('node', 'id') }
  end

  def grab_list_data(response_body)
    JSON.parse(response_body)['data'][board_parent_type]['boards']['edges'][0]['node']['lists']['edges']
  end
end
