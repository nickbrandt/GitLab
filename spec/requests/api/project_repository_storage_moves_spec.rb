# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectRepositoryStorageMoves do
  let(:user) { create(:admin) }
  let!(:storage_move) { create(:project_repository_storage_move, :scheduled) }

  describe 'GET /project_repository_storage_moves' do
    def get_project_repository_storage_moves
      get api('/project_repository_storage_moves', user)
    end

    it 'returns project repository storage moves' do
      get_project_repository_storage_moves

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(storage_move.id)
      expect(json_response.first['state']).to eq(storage_move.human_state_name)
    end

    it 'avoids N+1 queries', :request_store do
      control = ActiveRecord::QueryRecorder.new { get_project_repository_storage_moves }

      create(:project_repository_storage_move, :scheduled)

      expect { get_project_repository_storage_moves }.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /project_repository_storage_moves/:id' do
    it 'returns a project repository storage move' do
      get api("/project_repository_storage_moves/#{storage_move.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['id']).to eq(storage_move.id)
      expect(json_response['state']).to eq(storage_move.human_state_name)
    end
  end
end
