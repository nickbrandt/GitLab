# frozen_string_literal: true

require 'spec_helper'

describe Boards::ListsController do
  let(:group) { create(:group, :private) }
  let(:board)   { create(:board, group: group) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  before do
    group.add_maintainer(user)
    group.add_guest(guest)
  end

  describe 'GET index' do
    it 'returns a successful 200 response' do
      read_board_list user: user, board: board

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'application/json'
    end

    it 'returns a list of board lists' do
      create(:list, board: board)

      read_board_list user: user, board: board

      expect(response).to match_response_schema('lists', dir: 'ee')
      expect(json_response.length).to eq 3
    end

    context 'with unauthorized user' do
      before do
        group.group_member(user).destroy
      end

      it 'returns a forbidden 403 response' do
        read_board_list user: user, board: board

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def read_board_list(user:, board:)
      sign_in(user)

      get :index, params: { board_id: board.to_param }, format: :json
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      let(:label) { create(:group_label, group: group, name: 'Development') }

      it 'returns a successful 200 response' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns the created list' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to match_response_schema('list', dir: 'ee')
      end
    end

    context 'with max issue count' do
      let(:label) { create(:group_label, group: group, name: 'Development') }

      context 'with licensed wip limits' do
        it 'returns the created list' do
          create_board_list user: user, board: board, label_id: label.id, params: { max_issue_count: 2 }

          expect(response).to match_response_schema('list', dir: 'ee')
          expect(json_response).to include('max_issue_count' => 2)
        end
      end

      context 'without licensed wip limits' do
        before do
          stub_feature_flags(wip_limits: false)
        end

        it 'ignores max issue count' do
          create_board_list user: user, board: board, label_id: label.id, params: { max_issue_count: 2 }

          expect(response).to match_response_schema('list', dir: 'ee')
          expect(json_response).not_to include('max_issue_count')
        end
      end
    end

    context 'with max issue weight' do
      let(:label) { create(:group_label, group: group, name: 'Development') }

      context 'with licensed wip limits' do
        it 'returns the created list' do
          create_board_list user: user, board: board, label_id: label.id, params: { max_issue_weight: 3 }

          expect(response).to match_response_schema('list', dir: 'ee')
          expect(json_response).to include('max_issue_weight' => 3)
        end
      end

      context 'without licensed wip limits' do
        before do
          stub_feature_flags(wip_limits: false)
        end

        it 'ignores max issue count' do
          create_board_list user: user, board: board, label_id: label.id, params: { max_issue_weight: 3 }

          expect(response).to match_response_schema('list', dir: 'ee')
          expect(json_response).not_to include('max_issue_weight')
        end
      end
    end

    context 'with invalid params' do
      context 'when label is nil' do
        it 'returns a not found 404 response' do
          create_board_list user: user, board: board, label_id: nil

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when label that does not belongs to group' do
        it 'returns a not found 404 response' do
          label = create(:label, name: 'Development')

          create_board_list user: user, board: board, label_id: label.id

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        label = create(:group_label, group: group, name: 'Development')

        create_board_list user: guest, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def create_board_list(user:, board:, label_id:, params: {})
      sign_in(user)

      post :create, params: {
                      board_id: board.to_param,
                      list: { label_id: label_id }.merge(params)
                    },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }

    context 'when updating max limits' do
      before do
        sign_in(user)
      end

      it 'returns a successful 200 response when max issue count should be updated' do
        params = update_params_with_max_issue_count_of(42)

        patch :update, params: params, as: :json

        expect(response).to have_gitlab_http_status(200)
        expect(development.reload.max_issue_count).to eq(42)
      end

      it 'does not overwrite existing weight when max issue count is provided' do
        development.update!(max_issue_weight: 22)

        params = update_params_with_max_issue_count_of(42)

        patch :update, params: params, as: :json

        expect(response).to have_gitlab_http_status(200)
        expect(development.reload.max_issue_count).to eq(42)
        expect(development.reload.max_issue_weight).to eq(22)
      end

      it 'does not overwrite existing count when max issue weight is provided' do
        development.update!(max_issue_count: 22)

        params = update_params_with_max_issue_weight_of(42)

        patch :update, params: params, as: :json

        expect(response).to have_gitlab_http_status(200)
        expect(development.reload.max_issue_weight).to eq(42)
        expect(development.reload.max_issue_count).to eq(22)
      end

      context 'multiple fields update behavior' do
        shared_examples 'field updates' do
          it 'updates fields as expected' do
            params = update_params_with_list_params(update_params)

            patch :update, params: params, as: :json

            expect(response).to have_gitlab_http_status(200)

            reloaded_list = development.reload
            expect(reloaded_list.position).to eq(expected_position)
            expect(reloaded_list.preferences_for(user).collapsed).to eq(expected_collapsed)
            expect(reloaded_list.max_issue_count).to eq(expected_max_issue_count)
            expect(reloaded_list.max_issue_weight).to eq(expected_max_issue_weight)
          end
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_count: 99, position: 0, collapsed: true } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { true }
          let(:expected_max_issue_count) { 99 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { position: 0, collapsed: true } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { true }
          let(:expected_max_issue_count) { 0 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { position: 0 } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { nil }
          let(:expected_max_issue_count) { 0 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_count: 42 } }

          let(:expected_position) { 1 }
          let(:expected_collapsed) { nil }
          let(:expected_max_issue_count) { 42 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { collapsed: true } }

          let(:expected_position) { 1 }
          let(:expected_collapsed) { true }
          let(:expected_max_issue_count) { 0 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_count: 42, collapsed: true } }

          let(:expected_position) { 1 }
          let(:expected_collapsed) { true }
          let(:expected_max_issue_count) { 42 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_count: 42, position: 0 } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { nil }
          let(:expected_max_issue_count) { 42 }
          let(:expected_max_issue_weight) { 0 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_weight: 42, position: 0 } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { nil }
          let(:expected_max_issue_count) { 0 }
          let(:expected_max_issue_weight) { 42 }
        end

        it_behaves_like 'field updates' do
          let(:update_params) { { max_issue_count: 99, max_issue_weight: 42, position: 0 } }

          let(:expected_position) { 0 }
          let(:expected_collapsed) { nil }
          let(:expected_max_issue_count) { 99 }
          let(:expected_max_issue_weight) { 42 }
        end
      end

      it 'fails if negative max_issue_count is provided' do
        params = update_params_with_max_issue_count_of(-1)

        patch :update, params: params, as: :json

        expect(response).to have_gitlab_http_status(422)
        expect(development.reload.max_issue_count).to eq(0)
      end

      it 'fails if negative max_issue_weight is provided' do
        params = update_params_with_max_issue_weight_of(-1)

        patch :update, params: params, as: :json

        expect(response).to have_gitlab_http_status(422)
        expect(development.reload.max_issue_weight).to eq(0)
      end

      context 'when wip limits are not licensed' do
        before do
          stub_feature_flags(wip_limits: false)
        end

        it 'fails to update max issue count with expected status' do
          params = update_params_with_max_issue_count_of(2)

          patch :update, params: params, as: :json

          expect(response).to have_gitlab_http_status(422)
          expect(development.reload.max_issue_count).to eq(0)
        end

        it 'fails to update max issue weight with expected status' do
          params = update_params_with_max_issue_weight_of(2)

          patch :update, params: params, as: :json

          expect(response).to have_gitlab_http_status(422)
          expect(development.reload.max_issue_weight).to eq(0)
        end
      end

      def update_params_with_max_issue_count_of(count)
        update_params_with_list_params(max_issue_count: count)
      end

      def update_params_with_max_issue_weight_of(count)
        update_params_with_list_params(max_issue_weight: count)
      end

      def update_params_with_list_params(list_update_params)
        { namespace_id: group.to_param,
          project_id: board.project,
          board_id: board.to_param,
          id: development.to_param,
          list: list_update_params,
          format: :json }
      end
    end

    context 'with valid position' do
      it 'returns a successful 200 response' do
        move user: user, board: board, list: planning, position: 1

        expect(response).to have_gitlab_http_status(200)
      end

      it 'moves the list to the desired position' do
        move user: user, board: board, list: planning, position: 1

        expect(planning.reload.position).to eq 1
      end
    end

    context 'with invalid position' do
      it 'returns an unprocessable entity 422 response' do
        move user: user, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(422)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        move user: user, board: board, list: 999, position: 1

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a 422 unprocessable entity response' do
        move user: guest, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(422)
      end
    end

    def move(user:, board:, list:, position:)
      sign_in(user)
      params = {
        board_id: board.to_param,
        id: list.to_param,
        list: { position: position },
        format: :json
      }

      patch :update, params: params, as: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:planning) { create(:list, board: board, position: 0) }

    context 'with valid list id' do
      it 'returns a successful 200 response' do
        remove_board_list user: user, board: board, list: planning

        expect(response).to have_gitlab_http_status(200)
      end

      it 'removes list from board' do
        expect { remove_board_list user: user, board: board, list: planning }.to change(board.lists, :size).by(-1)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        remove_board_list user: user, board: board, list: 999

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        remove_board_list user: guest, board: board, list: planning

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def remove_board_list(user:, board:, list:)
      sign_in(user)

      delete :destroy, params: {
                         board_id: board.to_param,
                         id: list.to_param
                       },
                       format: :json
    end
  end
end
