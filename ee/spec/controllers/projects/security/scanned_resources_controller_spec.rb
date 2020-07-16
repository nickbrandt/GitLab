# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ScannedResourcesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

  let_it_be(:action_params) { { project_id: project, namespace_id: project.namespace, pipeline_id: pipeline } }

  before do
    stub_licensed_features(dast: true, security_dashboard: true)

    sign_in(user)
  end

  describe 'GET index' do
    let(:subject) { get :index, params: action_params, format: :csv }
    let(:parsed_csv_data) { CSV.parse(subject.body, headers: true) }

    before do
      project.add_developer(user)
    end

    context 'when DAST security scan is found' do
      before do
        create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
          create(:ee_ci_job_artifact, :dast, job: job, project: project)
        end
      end

      it 'returns a CSV representation of the scanned resources' do
        expect_next_instance_of(::Gitlab::Ci::Parsers::Security::ScannedResources) do |instance|
          expect(instance).to receive(:scanned_resources_for_csv).and_return([])
        end
        expect(subject).to have_gitlab_http_status(:ok)
      end

      context 'when the pipeline id is missing' do
        let_it_be(:action_params) { { project_id: project, namespace_id: project.namespace } }

        before do
          project.add_developer(user)
        end

        it 'raises an error when pipeline_id param is missing' do
          expect { subject }.to raise_error(ActionController::ParameterMissing)
        end
      end
    end
  end
end
