# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectMirror do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  describe 'POST /projects/:id/mirror/pull' do
    context 'when the project is not mirrored' do
      it 'returns error' do
        allow(project).to receive(:mirror?).and_return(false)

        post api("/projects/#{project.id}/mirror/pull", user)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when the project is mirrored' do
      before do
        allow_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)
      end

      context 'when it receives a "push" event' do
        shared_examples_for 'an API endpoint that triggers pull mirroring operation' do
          it 'executes UpdateAllMirrorsWorker' do
            expect(UpdateAllMirrorsWorker).to receive(:perform_async).once

            post api("/projects/#{project.id}/mirror/pull", user)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        shared_examples_for 'an API endpoint that does not trigger pull mirroring operation' do |status_code|
          it "does not execute UpdateAllMirrorsWorker and returns #{status_code}" do
            expect(UpdateAllMirrorsWorker).not_to receive(:perform_async)

            post api("/projects/#{project.id}/mirror/pull", user)

            expect(response).to have_gitlab_http_status(status_code)
          end
        end

        let(:project) do
          create(:project, :repository, namespace: user.namespace) do |project|
            create(:import_state, :mirror, state, project: project) do |import_state|
              import_state.update(next_execution_timestamp: 10.minutes.from_now)
            end
          end
        end

        context 'when import state is none' do
          let(:state) { :none }

          it_behaves_like 'an API endpoint that triggers pull mirroring operation'
        end

        context 'when import state is failed' do
          let(:state) { :failed }

          it_behaves_like 'an API endpoint that triggers pull mirroring operation'

          context "and retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
            before do
              project.import_state.update(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
            end

            it_behaves_like 'an API endpoint that does not trigger pull mirroring operation', 403
          end
        end

        context 'when import state is finished' do
          let(:state) { :finished }

          it_behaves_like 'an API endpoint that triggers pull mirroring operation'
        end

        context 'when import state is scheduled' do
          let(:state) { :scheduled }

          it_behaves_like 'an API endpoint that does not trigger pull mirroring operation', 200
        end

        context 'when import state is started' do
          let(:state) { :started }

          it_behaves_like 'an API endpoint that does not trigger pull mirroring operation', 200
        end
      end

      context 'when it receives a "pull_request" event' do
        let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }
        let(:branch) { project.repository.branches.first }
        let(:source_branch) { branch.name }
        let(:source_sha) { branch.target }
        let(:action) { 'opened' }

        let(:params) do
          {
            pull_request: {
              number: 123,
              head: {
                ref: source_branch,
                sha: source_sha,
                repo: { full_name: 'the-repo' }
              },
              base: {
                ref: 'master',
                sha: 'a09386439ca39abe575675ffd4b89ae824fec22f',
                repo: { full_name: 'the-repo' }
              }
            },
            action: action
          }
        end

        before do
          create(:import_state, :mirror, :finished, project: project)
        end

        it 'triggers a pipeline for pull request' do
          pipeline_params = {
            ref: Gitlab::Git::BRANCH_REF_PREFIX + branch.name,
            source_sha: branch.target,
            target_sha: 'a09386439ca39abe575675ffd4b89ae824fec22f'
          }
          expect(Ci::CreatePipelineService).to receive(:new).with(project, user, pipeline_params).and_return(create_pipeline_service)
          expect(create_pipeline_service).to receive(:execute).with(:external_pull_request_event, any_args)

          post api("/projects/#{project.id}/mirror/pull", user), params: params

          expect(response).to have_gitlab_http_status(200)
        end

        context 'when any param is missing' do
          let(:source_sha) { nil }

          it 'returns the error message' do
            post api("/projects/#{project.id}/mirror/pull", user), params: params

            expect(response).to have_gitlab_http_status(400)
          end
        end

        context 'when action is not supported' do
          let(:action) { 'assigned' }

          it 'ignores it and return success status' do
            expect(Ci::CreatePipelineService).not_to receive(:new)

            post api("/projects/#{project.id}/mirror/pull", user), params: params

            expect(response).to have_gitlab_http_status(422)
          end
        end
      end

      context 'when user' do
        let(:project_mirrored) { create(:project, :repository, :mirror, :import_finished, namespace: user.namespace) }

        def project_member(role, user)
          create(:project_member, role, user: user, project: project_mirrored)
        end

        context 'is unauthenticated' do
          it 'returns authentication error' do
            post api("/projects/#{project_mirrored.id}/mirror/pull")

            expect(response).to have_gitlab_http_status(401)
          end
        end

        context 'is authenticated as developer' do
          it 'returns forbidden error' do
            project_member(:developer, user2)

            post api("/projects/#{project_mirrored.id}/mirror/pull", user2)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'is authenticated as reporter' do
          it 'returns forbidden error' do
            project_member(:reporter, user2)

            post api("/projects/#{project_mirrored.id}/mirror/pull", user2)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'is authenticated as guest' do
          it 'returns forbidden error' do
            project_member(:guest, user2)

            post api("/projects/#{project_mirrored.id}/mirror/pull", user2)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'is authenticated as maintainer' do
          it 'triggers the pull mirroring operation' do
            project_member(:maintainer, user2)

            post api("/projects/#{project_mirrored.id}/mirror/pull", user2)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context 'is authenticated as owner' do
          it 'triggers the pull mirroring operation' do
            post api("/projects/#{project_mirrored.id}/mirror/pull", user)

            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'authenticating from GitHub signature' do
        let(:visibility) { Gitlab::VisibilityLevel::PUBLIC }
        let(:project_mirrored) { create(:project, :repository, :mirror, :import_finished, visibility: visibility) }

        def do_post
          post api("/projects/#{project_mirrored.id}/mirror/pull"), params: {}, headers: { 'X-Hub-Signature' => 'signature' }
        end

        context "when it's valid" do
          before do
            Grape::Endpoint.before_each do |endpoint|
              allow(endpoint).to receive(:project).and_return(project_mirrored)
              allow(endpoint).to receive(:valid_github_signature?).and_return(true)
            end
          end

          it 'syncs the mirror' do
            expect(project_mirrored.import_state).to receive(:force_import_job!)

            do_post
          end
        end

        context "when it's invalid" do
          before do
            Grape::Endpoint.before_each do |endpoint|
              allow(endpoint).to receive(:project).and_return(project_mirrored)
              allow(endpoint).to receive(:valid_github_signature?).and_return(false)
            end
          end

          after do
            Grape::Endpoint.before_each nil
          end

          it "doesn't sync the mirror" do
            expect(project_mirrored.import_state).not_to receive(:force_import_job!)

            post api("/projects/#{project_mirrored.id}/mirror/pull"), params: {}, headers: { 'X-Hub-Signature' => 'signature' }
          end

          context 'with a public project' do
            let(:visibility) { Gitlab::VisibilityLevel::PUBLIC }

            it 'returns a 401 status' do
              do_post

              expect(response).to have_gitlab_http_status(401)
            end
          end

          context 'with an internal project' do
            let(:visibility) { Gitlab::VisibilityLevel::INTERNAL }

            it 'returns a 404 status' do
              do_post

              expect(response).to have_gitlab_http_status(404)
            end
          end

          context 'with a private project' do
            let(:visibility) { Gitlab::VisibilityLevel::PRIVATE }

            it 'returns a 404 status' do
              do_post

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end
  end
end
