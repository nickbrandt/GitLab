# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::DependenciesController do
  describe 'GET index.json' do
    set(:project) { create(:project, :repository, :public) }
    set(:user) { create(:user) }

    subject { get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json }

    before do
      project.add_developer(user)
    end

    context 'with authorized user' do
      before do
        sign_in(user)
      end

      context 'when feature is available' do
        it "returns a list of dependencies" do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Array)
          expect(json_response.length).to eq 20
        end

        it 'returns paginated list' do
          get :index, params: { namespace_id: project.namespace, project_id: project, page: 2 }, format: :json

          expect(json_response.length).to eq 20
        end

        it 'returns sorted list' do
          get :index, params: { namespace_id: project.namespace, project_id: project, sort_by: 'type', sort: 'desc' }, format: :json

          sorted = json_response.sort_by { |a| a[:type] }.reverse

          expect(json_response[0][:type]).to eq(sorted[0][:type])
          expect(json_response[19][:type]).to eq(sorted[19][:type])
        end
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(bill_of_materials: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
