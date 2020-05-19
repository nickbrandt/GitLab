# frozen_string_literal: true

require 'spec_helper'

describe API::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers

  let_it_be(:project) { create(:project, :repository) }

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

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to include(
              "id" => build.id,
              "variables" => include("key" => 'KEY', "value" => 'value', "public" => true, "masked" => false),
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
            expect(response).to have_gitlab_http_status(:no_content)
          end
        end
      end

      context 'secrets management' do
        let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
        let(:secrets) do
          {
            vault: {
              db_vault: {
                url: 'https://db.vault.example.com',
                auth: {
                  name: 'jwt',
                  path: 'jwt',
                  data: { role: 'production' }
                },
                secrets: {
                  DATABASE_CREDENTIALS: {
                    engine: { name: 'kv-v2', path: 'kv-v2' },
                    path: 'production/db',
                    fields: %w(username password),
                    strategy: 'read'
                  }
                }
              }
            }
          }
        end

        before do
          create(:ci_build, pipeline: pipeline, options: options)
        end

        context 'when ci_secrets_management_vault feature flag is enabled' do
          before do
            stub_feature_flags(ci_secrets_management_vault: true)
          end

          context 'when secrets management feature is available' do
            before do
              stub_licensed_features(ci_secrets_management: true)
            end

            context 'job has secrets configured' do
              let(:options) { { script: ['echo'], secrets: secrets } }

              it 'returns secrets configuration' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['secrets']).to eq(
                  {
                    'vault' => {
                      'db_vault' => {
                        'url' => 'https://db.vault.example.com',
                        'auth' => {
                          'name' => 'jwt',
                          'path' => 'jwt',
                          'data' => { 'role' => 'production' }
                        },
                        'secrets' => {
                          'DATABASE_CREDENTIALS' => {
                            'engine' => { 'name' => 'kv-v2', 'path' => 'kv-v2' },
                            'path' => 'production/db',
                            'fields' => %w(username password),
                            'strategy' => 'read'
                          }
                        }
                      }
                    }
                  }
                )
              end
            end

            context 'job does not have secrets configured' do
              let(:options) { { script: ['echo'] } }

              it 'doesn not return secrets configuration' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['secrets']).to eq(nil)
              end
            end
          end

          context 'when secrets management feature is not available' do
            before do
              stub_licensed_features(ci_secrets_management: false)
            end

            context 'job has secrets configured' do
              let(:options) { { script: ['echo'], secrets: secrets } }

              it 'doesn not return secrets configuration' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['secrets']).to eq(nil)
              end
            end
          end
        end

        context 'when ci_secrets_management_vault feature flag is disabled' do
          before do
            stub_feature_flags(ci_secrets_management_vault: false)
            stub_licensed_features(ci_secrets_management: true)
          end

          context 'job has secrets configured' do
            let(:options) { { script: ['echo'], secrets: secrets } }

            it 'doesn not return secrets configuration' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['secrets']).to eq(nil)
            end
          end

          context 'job does not secrets configured' do
            let(:options) { { script: ['echo'] } }

            it 'doesn not return secrets configuration' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['secrets']).to eq(nil)
            end
          end
        end
      end

      def request_job(token = runner.token, **params)
        post api('/jobs/request'), params: params.merge(token: token)
      end
    end
  end
end
