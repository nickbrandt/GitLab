# frozen_string_literal: true

require 'spec_helper'

describe 'Running a DAST Scan' do
  include GraphqlHelpers

  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:project_path) { project.full_path }
  let(:target_url) { FFaker::Internet.uri(:https) }
  let(:branch) { SecureRandom.hex }
  let(:scan_type) { Types::DastScanTypeEnum.enum[:passive] }

  let(:mutation) do
    graphql_mutation(
      :run_dast_scan,
      branch: branch,
      project_path: project_path,
      target_url: target_url,
      scan_type: scan_type
    )
  end

  def mutation_response
    graphql_mutation_response(:run_dast_scan)
  end

  context 'when on demand scan feature is not enabled' do
    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not ' \
                             'exist or you don\'t have permission to perform this action']
  end

  context 'when on demand scan feature is enabled' do
    before do
      stub_feature_flags(security_on_demand_scans_feature_flag: true)
    end

    context 'when the user does not have permission to run a dast scan' do
      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not ' \
                               'exist or you don\'t have permission to perform this action']
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(current_user)
      end

      it 'returns a pipeline_url containing the correct path' do
        post_graphql_mutation(mutation, current_user: current_user)
        pipeline = Ci::Pipeline.last
        expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
          project,
          pipeline
        )
        expect(mutation_response['pipelineUrl']).to eq(expected_url)
      end

      context 'when the pipeline could not be created' do
        before do
          allow(Ci::Pipeline).to receive(:create!).and_raise(StandardError)
        end

        it_behaves_like 'a mutation that returns errors in the response', errors: ['Could not create pipeline']
      end

      context 'when the stage could not be created' do
        before do
          allow(Ci::Stage).to receive(:create!).and_raise(StandardError)
        end

        it_behaves_like 'a mutation that returns errors in the response', errors: ['Could not create stage']
      end

      context 'when the build could not be created' do
        before do
          allow(Ci::Build).to receive(:create!).and_raise(StandardError)
        end

        it_behaves_like 'a mutation that returns errors in the response', errors: ['Could not create build']
      end

      context 'when the build could not be enqueued' do
        before do
          allow_any_instance_of(Ci::Build).to receive(:enqueue!).and_raise(StandardError)
        end

        it_behaves_like 'a mutation that returns errors in the response', errors: ['Could not enqueue build']
      end
    end
  end
end
