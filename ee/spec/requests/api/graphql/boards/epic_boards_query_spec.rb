# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of epic boards' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board1) { create(:epic_board, group: group, name: 'B', hide_closed_list: true, hide_backlog_list: false) }
  let_it_be(:board2) { create(:epic_board, group: group, name: 'A') }
  let_it_be(:board3) { create(:epic_board, group: group, name: 'a') }

  def pagination_query(params = {})
    graphql_query_for(:group, { full_path: group.full_path },
      query_nodes(:epicBoards, all_graphql_fields_for('epic_boards'.classify), include_pagination_info: true, args: params)
    )
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when the user does not have access to the epic board group' do
    it 'returns nil group' do
      post_graphql(pagination_query, current_user: current_user)

      expect(graphql_data['group']).to be_nil
    end
  end

  context 'when user can access the epic board group' do
    before do
      group.add_developer(current_user)
    end

    describe 'sorting and pagination' do
      let(:data_path) { [:group, :epicBoards] }
      let(:expected_results) { [board2.to_global_id.to_s, board3.to_global_id.to_s, board1.to_global_id.to_s] }

      def pagination_results_data(nodes)
        nodes.map { |board| board['id'] }
      end

      it_behaves_like 'sorted paginated query' do
        # currently we don't support custom sorting for epic boards,
        # nil value will be ignored by ::Graphql::Arguments
        let(:sort_param) { nil }
        let(:first_param) { 2 }
      end
    end

    context 'field values' do
      let(:query) do
        graphql_query_for(:group, { fullPath: group.full_path }, query_graphql_field(:epicBoard, { id: board1.to_global_id.to_s }, epic_board_fields))
      end

      let(:epic_board_fields) do
        <<~QUERY
        hideBacklogList
        hideClosedList
        QUERY
      end

      it 'returns the correct values for hiding board lists' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data.dig('group', 'epicBoard', 'hideBacklogList')).to eq board1.hide_backlog_list
        expect(graphql_data.dig('group', 'epicBoard', 'hideClosedList')).to eq board1.hide_closed_list
      end
    end
  end
end
