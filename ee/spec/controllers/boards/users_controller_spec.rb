require 'spec_helper'

describe Boards::UsersController do
  let(:group) { create(:group, :private) }
  let(:board) { create(:board, group: group) }
  let(:guest) { create(:user) }
  let(:user)  { create(:user) }

  describe 'GET index' do
    context 'with authorized user' do
      before do
        group.add_maintainer(user)
        group.add_guest(guest)

        sign_in(user)
      end

      it 'returns a list of all members of board parent' do
        get :index, namespace_id: group.to_param,
                    board_id: board.to_param,
                    format: :json

        parsed_response = JSON.parse(response.body)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type).to eq 'application/json'
        expect(parsed_response).to all(match_schema('entities/user'))
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      shared_examples 'unauthorized board user listing' do
        it 'returns a forbidden 403 response' do
          get :index, board_id: board.to_param, format: :json

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'with private group board' do
        it_behaves_like 'unauthorized board user listing'
      end

      context 'with private project board' do
        let(:project) { create(:project) }
        let(:board) { create(:board, project: project) }

        it_behaves_like 'unauthorized board user listing'
      end
    end
  end
end
