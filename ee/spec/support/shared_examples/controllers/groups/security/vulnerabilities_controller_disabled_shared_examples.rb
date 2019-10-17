# frozen_string_literal: true

shared_examples 'disabled group vulnerability findings controller' do
  describe 'GET index.json' do
    it 'is disabled and returns "not found" response' do
      get :index, params: { group_id: group }, format: :json

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET history.json' do
    it 'is disabled and returns "not found" response' do
      get :history, params: { group_id: group }, format: :json

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
