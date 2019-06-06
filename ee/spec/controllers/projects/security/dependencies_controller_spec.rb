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
        before do
          stub_licensed_features(dependency_list: true)
        end

        context 'with existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

          context 'without pagination params' do
            it "returns a list of dependencies" do
              subject

              expect(response).to have_gitlab_http_status(200)
              expect(json_response).to be_a(Array)
              expect(json_response.length).to eq(21)
            end
          end

          context 'with params' do
            it 'returns paginated list' do
              get :index, params: { namespace_id: project.namespace, project_id: project, page: 2 }, format: :json

              expect(json_response.length).to eq(1)
            end

            it 'returns sorted list' do
              get :index, params: { namespace_id: project.namespace, project_id: project, sort_by: 'packager', sort: 'desc', page: 1 }, format: :json

              expect(json_response.length).to eq(20)
              expect(json_response[0]['packager']).to eq('Ruby (Bundler)')
              expect(json_response[19]['packager']).to eq('JavaScript (Yarn)')
            end
          end
        end
      end

      context 'when feature is not available' do
        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
