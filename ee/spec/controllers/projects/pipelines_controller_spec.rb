require 'spec_helper'

describe Projects::PipelinesController do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  describe 'GET security' do
    set(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :legacy_sast, pipeline: pipeline)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true)

          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without sast artifact' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true)

          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end

  describe 'GET licenses' do
    set(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    context 'with a license management artifact' do
      before do
        build = create(:ci_build, pipeline: pipeline)
        create(:ee_ci_job_artifact, :license_management, job: build)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(license_management: true)

          get :licenses, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :licenses, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without license management artifact' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(license_management: true)

          get :licenses, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :licenses, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end
end
