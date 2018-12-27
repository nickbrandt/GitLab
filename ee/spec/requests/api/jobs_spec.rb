require 'spec_helper'

describe API::Jobs do
  set(:project) do
    create(:project, :repository, public_builds: false)
  end

  set(:pipeline) do
    create(:ci_pipeline, :success,
      project: project,
      sha: project.commit('master').sha,
      ref: 'master')
  end

  let!(:job) { create(:ci_build, :success, pipeline: pipeline) }
  let!(:running_job) { create(:ci_build, :running, pipeline: pipeline, user: api_user) }

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:cross_project_pipeline_enabled) { true }

  before do
    stub_licensed_features(cross_project_pipelines: cross_project_pipeline_enabled)
    project.add_developer(user)
    stub_artifacts_object_storage
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    shared_examples 'downloads artifact' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
      end

      it 'returns specific job artifacts' do
        expect(response).to have_gitlab_http_status(200)
        expect(response.headers.to_h).to include(download_headers)
        expect(response.body).to match_file(job.artifacts_file.file.file)
      end
    end

    context 'authorized by job_token' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

      before do
        get api("/projects/#{project.id}/jobs/#{job.id}/artifacts"), job_token: running_job.token
      end

      context 'user is developer' do
        let(:api_user) { user }

        it_behaves_like 'downloads artifact'
      end

      context 'when anonymous user is accessing private artifacts' do
        let(:api_user) { nil }

        it 'hides artifacts and rejects request' do
          expect(project).to be_private
          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'feature is disabled for EES' do
        let(:api_user) { user }
        let(:cross_project_pipeline_enabled) { false }

        it 'disallows access to the artifacts' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:job) { create(:ci_build, :success, pipeline: pipeline) }
    let!(:artifact) { create(:ci_job_artifact, :archive, job: job) }

    shared_examples 'a valid file' do
      context 'when artifacts are stored locally' do
        let(:download_headers) do
          { 'Content-Transfer-Encoding' => 'binary',
            'Content-Disposition' =>
              "attachment; filename=#{artifact.filename}" }
        end

        it { expect(response).to have_http_status(:ok) }
        it { expect(response.headers.to_h).to include(download_headers) }
      end

      context 'when artifacts are stored remotely' do
        let(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

        it 'returns location redirect' do
          expect(response).to have_http_status(:found)
        end
      end
    end

    context 'when using job_token to authenticate' do
      let(:running_job) { create(:ci_build, :running, pipeline: pipeline, user: api_user) }

      before do
        get api("/projects/#{project.id}/jobs/artifacts/master/download"), job: job.name, job_token: running_job.token
      end

      context 'when user is reporter' do
        it_behaves_like 'a valid file'
      end

      context 'when user is admin, but not member' do
        let(:api_user) { create(:admin) }

        it 'does not allow to see that artfiact is present' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
