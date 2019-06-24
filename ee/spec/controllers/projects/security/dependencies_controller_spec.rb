# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::DependenciesController do
  describe 'GET index.json' do
    set(:project) { create(:project, :repository, :public) }
    set(:user) { create(:user) }
    let(:params) { { namespace_id: project.namespace, project_id: project } }

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

        it 'counts usage of the feature' do
          expect(::Gitlab::UsageCounters::DependencyList).to receive(:increment).with(project.id)

          get :index, params: params, format: :json
        end

        context 'with existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

          before do
            get :index, params: params, format: :json
          end

          context 'without pagination params' do
            it 'returns a hash with dependencies' do
              expect(json_response).to be_a(Hash)
              expect(json_response['dependencies'].length).to eq(21)
            end

            it 'returns status ok' do
              expect(json_response['report']['status']).to eq('ok')
            end

            it 'returns job path' do
              job_path = "/#{project.full_path}/builds/#{pipeline.builds.last.id}"

              expect(json_response['report']['job_path']).to eq(job_path)
            end

            it 'returns success code' do
              expect(response).to have_gitlab_http_status(200)
            end
          end

          context 'with params' do
            context 'with sorting params' do
              let(:params) do
                {
                  namespace_id: project.namespace,
                  project_id: project,
                  sort_by: 'packager',
                  sort: 'desc',
                  page: 1
                }
              end

              it 'returns sorted list' do
                expect(json_response['dependencies'].first['packager']).to eq('Ruby (Bundler)')
                expect(json_response['dependencies'].last['packager']).to eq('JavaScript (Yarn)')
              end

              it 'return 20 dependencies' do
                expect(json_response['dependencies'].length).to eq(20)
              end
            end

            context 'with pagination params' do
              let(:params) { { namespace_id: project.namespace, project_id: project, page: 2 } }

              it 'returns paginated list' do
                expect(json_response['dependencies'].length).to eq(1)
                expect(response).to include_pagination_headers
              end
            end
          end
        end

        context 'without existing report' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

          before do
            get :index, params: params, format: :json
          end

          it 'returns job_not_set_up status' do
            expect(json_response['report']['status']).to eq('job_not_set_up')
          end

          it 'returns a nil job_path' do
            expect(json_response['report']['job_path']).to be_nil
          end
        end

        context 'when report doesn\'t have dependency list' do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

          before do
            get :index, params: params, format: :json
          end

          it 'returns no_dependencies status' do
            expect(json_response['report']['status']).to eq('no_dependencies')
          end
        end

        context 'when job failed' do
          let!(:pipeline) { create(:ee_ci_pipeline, :success, project: project) }
          let!(:build) { create(:ee_ci_build, :dependency_list, :failed, :allowed_to_fail) }

          before do
            pipeline.builds << build

            get :index, params: params, format: :json
          end

          it 'returns job_failed status' do
            expect(json_response['report']['status']).to eq('job_failed')
          end
        end
      end

      context 'when feature is not available' do
        before do
          get :index, params: params, format: :json
        end

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        get :index, params: params, format: :json
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
