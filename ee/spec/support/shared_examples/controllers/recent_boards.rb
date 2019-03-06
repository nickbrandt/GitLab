# frozen_string_literal: true

require 'spec_helper'

shared_examples 'returns recently visited boards' do
  let(:boards) { create_list(:board, 8, parent: parent) }

  context 'unauthenticated' do
    it 'returns a 401' do
      sign_out(user)

      get_recent_boards

      expect(response).to have_gitlab_http_status(401)
    end
  end

  it 'returns last 4 visited boards' do
    [0, 2, 5, 3, 7, 1].each_with_index do |board_index, i|
      visit_board(boards[board_index], Time.now + i.minutes)
    end

    get_recent_boards

    expect(json_response.length).to eq(4)
    expect(json_response.map { |b| b['id'] }).to eq([1, 7, 3, 5].map { |i| boards[i].id })
  end

  def visit_board(board, time)
    if parent.is_a?(Group)
      create(:board_group_recent_visit, group: parent, board: board, user: user, updated_at: time)
    else
      create(:board_project_recent_visit, project: parent, board: board, user: user, updated_at: time)
    end
  end

  def get_recent_boards
    params = if parent.is_a?(Group)
               { group_id: parent }
             else
               { namespace_id: parent.namespace, project_id: parent }
             end

    get :recent, params: params, format: :json
  end
end
