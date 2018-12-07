# frozen_string_literal: true

require 'spec_helper'

describe API::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers

  set(:project) { create(:project, :repository) }

  describe '/api/v4/jobs' do
    let(:runner) { create(:ci_runner, :project, projects: [project]) }

    describe 'POST /api/v4/jobs/request' do
      context 'for web-ide job' do
        let(:user) { create(:user) }
        let(:service) { Ci::CreateWebIdeTerminalService.new(project, user, ref: 'master').execute }
        let(:pipeline) { service[:pipeline] }
        let(:build) { pipeline.builds.first }

        before do
          stub_licensed_features(web_ide_terminal: true)
          stub_webide_config_file(config_content)
          project.add_maintainer(user)

          pipeline
        end

        let(:config_content) do
          'terminal: { image: ruby, services: [mysql], before_script: [ls], tags: [tag-1], variables: { KEY: value } }'
        end

        context 'when runner has matching tag' do
          before do
            runner.update!(tag_list: ['tag-1'])
          end

          it 'successfully picks job' do
            request_job

            build.reload

            expect(build).to be_running
            expect(build.runner).to eq(runner)

            expect(response).to have_http_status(:created)
            expect(json_response).to include(
              "id" => build.id,
              "variables" => include("key" => 'KEY', "value" => 'value', "public" => true),
              "image" => a_hash_including("name" => 'ruby'),
              "services" => all(a_hash_including("name" => 'mysql')),
              "job_info" => a_hash_including("name" => 'terminal', "stage" => 'terminal'))
          end
        end

        context 'when runner does not have matching tags' do
          it 'does not pick a job' do
            request_job

            build.reload

            expect(build).to be_pending
            expect(response).to have_http_status(204)
          end
        end
      end

      def request_job(token = runner.token, **params)
        post api('/jobs/request'), params.merge(token: token)
      end
    end
  end
end
