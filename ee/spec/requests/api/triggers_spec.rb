# frozen_string_literal: true

require 'spec_helper'

describe API::Triggers do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :auto_devops, creator: user) }

  describe 'POST /projects/:project_id/trigger/pipeline' do
    context 'when triggering a pipeline from a job token' do
      let(:other_job) { create(:ci_build, :running, user: other_user) }
      let(:params) { { ref: 'refs/heads/other-branch' } }

      subject do
        post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{other_job.token}"), params: params
      end

      context 'without user' do
        let(:other_user) { nil }

        it 'does not leak the presence of project when using valid token' do
          subject

          expect(response).to have_http_status(404)
        end
      end

      context 'for unreleated user' do
        let(:other_user) { create(:user) }

        it 'does not leak the presence of project when using valid token' do
          subject

          expect(response).to have_http_status(404)
        end
      end

      context 'for related user' do
        let(:other_user) { create(:user) }

        context 'with reporter permissions' do
          before do
            project.add_reporter(other_user)
          end

          it 'forbids to create a pipeline' do
            subject

            expect(response).to have_http_status(400)
            expect(json_response['message']).to eq("base" => ["Insufficient permissions to create a new pipeline"])
          end
        end

        context 'with developer permissions' do
          before do
            project.add_developer(other_user)
          end

          it 'creates a new pipeline' do
            expect { subject }.to change(Ci::Pipeline, :count)

            expect(response).to have_http_status(201)
            expect(Ci::Pipeline.last.source).to eq('cross_project_pipeline')
            expect(Ci::Pipeline.last.triggered_by_pipeline).not_to be_nil
            expect(Ci::Sources::Pipeline.last).to have_attributes(
              pipeline_id: (a_value > 0),
              source_pipeline_id: (a_value > 0),
              source_job_id: (a_value > 0),
              source_project_id: (a_value > 0)
            )
          end

          context 'when build is complete' do
            before do
              other_job.success
            end

            it 'does not create a pipeline' do
              subject

              expect(response).to have_http_status(400)
              expect(json_response['message']).to eq('400 Job has to be running')
            end
          end

          context 'when variables are defined' do
            let(:params) do
              { ref: 'refs/heads/other-branch',
                variables: { 'KEY' => 'VALUE' } }
            end

            it 'creates a new pipeline with a variable' do
              expect { subject }.to change(Ci::Pipeline, :count)
                                .and change(Ci::PipelineVariable, :count)

              expect(response).to have_http_status(201)
              expect(Ci::Pipeline.last.source).to eq('cross_project_pipeline')
              expect(Ci::Pipeline.last.triggered_by_pipeline).not_to be_nil
              expect(Ci::Pipeline.last.variables.map { |v| { v.key => v.value } }.last).to eq(params[:variables])
            end
          end
        end
      end
    end
  end
end
