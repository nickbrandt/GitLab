# frozen_string_literal: true

require 'spec_helper'

describe API::Boards do
  set(:user) { create(:user) }
  set(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }
  set(:milestone) { create(:milestone, project: board_parent) }
  set(:board) { create(:board, project: board_parent, milestone: milestone, assignee: user) }

  it_behaves_like 'multiple and scoped issue boards', "/projects/:id/boards"

  describe 'POST /projects/:id/boards/:board_id/lists' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    it_behaves_like 'milestone board list'
    it_behaves_like 'assignee board list'
  end

  context 'GET /projects/:id/boards/:board_id with special milestones' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}" }

    it 'returns board with Upcoming milestone' do
      board.update(milestone_id: Milestone::Upcoming.id)

      get api(url, user)

      expect(json_response["milestone"]["title"]).to eq(Milestone::Upcoming.title)
    end

    it 'returns board with Started milestone' do
      board.update(milestone_id: Milestone::Started.id)

      get api(url, user)

      expect(json_response["milestone"]["title"]).to eq(Milestone::Started.title)
    end
  end

  describe 'GET /projects/:id/boards/:board_id/lists with max_issue_count' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    let!(:list) { create(:list, board: board) }

    context 'with WIP limits license' do
      before do
        stub_licensed_features(wip_limits: true)

        get api(url, user)
      end

      it 'includes max_issue_count' do
        all_lists_in_response(include: 'max_issue_count')
      end

      it 'includes max_issue_weight' do
        all_lists_in_response(include: 'max_issue_weight')
      end
    end

    context 'without WIP limits license' do
      before do
        stub_licensed_features(wip_limits: false)

        get api(url, user)
      end

      it 'does not include max_issue_weight' do
        all_lists_in_response(do_not_include: 'max_issue_weight')
      end

      it 'does not include max_issue_count' do
        all_lists_in_response(do_not_include: 'max_issue_count')
      end
    end

    def all_lists_in_response(params)
      expect(json_response).not_to be_empty

      if params.key?(:include)
        expect(json_response).to all(include(params[:include]))
      elsif params.key?(:do_not_include)
        expect(json_response.none? { |list_response| list_response.include?(params[:do_not_include]) }).to be_truthy
      end
    end
  end
end
