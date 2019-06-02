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
              expect(json_response).to be_a(Hash)
              expect(json_response.keys).to include('dependencies', 'report')
              expect(json_response['dependencies'].length).to eq(21)
              expect(json_response['report']['status']).to eq('ok')
            end
          end

          context 'with pagination params' do
            it 'returns paginated list' do
              get :index, params: { namespace_id: project.namespace, project_id: project, page: 2 }, format: :json

              expect(json_response['dependencies'].length).to eq 1
            end

            it 'returns sorted list' do
              get :index, params: { namespace_id: project.namespace, project_id: project, sort_by: 'type', sort: 'desc', page: 1 }, format: :json

              dependencies = json_response['dependencies']
              sorted = dependencies.sort_by { |a| a[:type] }.reverse

              expect(dependencies[0][:type]).to eq(sorted[0][:type])
              expect(dependencies[19][:type]).to eq(sorted[19][:type])
            end
          end
        end

        context 'without existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

          it 'returns job_not_set_up status' do
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['dependencies'].length).to eq(0)
            expect(json_response['report']['status']).to eq('job_not_set_up')
          end
        end

        context 'when report doesn\'t have dependency list' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

          it 'returns job_failed status' do
            path = "/#{project.namespace.name}/#{project.name}/builds/#{pipeline.builds.last.id}"
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['dependencies'].length).to eq(0)
            expect(json_response['report']['status']).to eq('job_failed')
            expect(json_response['report']['job_path']).to eq(path)
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
