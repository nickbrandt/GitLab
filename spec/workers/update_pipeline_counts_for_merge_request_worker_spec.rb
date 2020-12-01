# frozen_string_literal: true

require "spec_helper"

RSpec.describe UpdatePipelineCountsForMergeRequestWorker do
  describe "#perform" do
    let_it_be(:project) { create_default(:project, :repository) }
    let(:merge_request) { create(:merge_request, project: project) }
    let!(:pipeline) { create(:ci_pipeline, merge_request: merge_request, project: merge_request.project) }

    before do
      # Ensure that the count is current, due to the test environment
      #
      merge_request.update_pipelines_count

      # Now create a pipeline for testing that counts are incremented as
      #   expected
      #
      create(:ci_pipeline, merge_request: merge_request, project: merge_request.project)
    end

    it "updates the pipeline counts of the merge_request" do
      expect { subject.perform(merge_request.id) }
        .to change { merge_request.reload.target_project_pipelines_count }.by(1)
        .and change { merge_request.reload.source_project_pipelines_count }.by(1)
        .and change { merge_request.reload.total_pipelines_count.to_i }.by(1)
    end

    # it_behaves_like "an idempotent worker" do
    #   let(:job_args) { merge_request.id }
    #
    #   it "updates the count accurately" do
    #     subject
    #
    #     expect(merge_request.reload.head_pipeline_id).to eq(pipeline.id)
    #   end
    # end
  end
end
