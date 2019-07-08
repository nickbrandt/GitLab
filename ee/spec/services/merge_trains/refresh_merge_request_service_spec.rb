# frozen_string_literal: true

require 'spec_helper'

describe MergeTrains::RefreshMergeRequestService do
  set(:project) { create(:project, :repository) }
  set(:maintainer) { create(:user) }
  let(:service) { described_class.new(project, maintainer) }

  before do
    project.add_maintainer(maintainer)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    let!(:merge_request) do
      create(:merge_request, :on_train, train_creator: maintainer,
        source_branch: 'feature', source_project: project,
        target_branch: 'master', target_project: project)
    end

    shared_examples_for 'drops the merge request from the merge train' do
      let(:expected_reason) { 'unknown' }

      it do
        expect_next_instance_of(AutoMerge::MergeTrainService) do |service|
          expect(service).to receive(:abort).with(merge_request, kind_of(String))
        end

        subject
      end
    end

    context 'when merge train project configuration is disabled' do
      before do
        project.update!(merge_trains_enabled: false)
      end

      it_behaves_like 'drops the merge request from the merge train' do
        let(:expected_reason) { 'project disabled merge trains' }
      end

      after do
        project.update!(merge_trains_enabled: true)
      end
    end

    context 'when merge request is not under a mergeable state' do
      before do
        merge_request.update!(title: merge_request.wip_title)
      end

      it_behaves_like 'drops the merge request from the merge train' do
        let(:expected_reason) { 'merge request is not mergeable' }
      end
    end

    context 'when pipeline for merge train failed' do
      let(:pipeline) { create(:ci_pipeline, :failed) }

      before do
        merge_request.merge_train.update!(pipeline: pipeline)
      end

      it_behaves_like 'drops the merge request from the merge train' do
        let(:expected_reason) { 'pipeline did not succeed' }
      end
    end

    context 'when pipeline has not been created yet' do
      context 'when the merge request is the first queue' do
        it 'creates a pipeline for merge train' do
          expect_next_instance_of(MergeTrains::CreatePipelineService, project, maintainer) do |pipeline_service|
            expect(pipeline_service).to receive(:execute).with(merge_request).and_call_original
          end

          subject
        end

        context 'when it failed to create a pipeline' do
          before do
            allow_any_instance_of(MergeTrains::CreatePipelineService).to receive(:execute) { { result: :error, message: 'failed to create pipeline' } }
          end

          it_behaves_like 'drops the merge request from the merge train' do
            let(:expected_reason) { 'failed to create pipeline' }
          end
        end
      end

      context 'when the merge request is not the first queue' do
        before do
          allow(merge_request.merge_train).to receive(:first_in_train?) { false }
        end

        it 'does not create a pipeline for merge train' do
          expect(MergeTrains::CreatePipelineService).not_to receive(:new)

          subject
        end
      end
    end

    context 'when pipeline for merge train succeeded' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      before do
        allow(pipeline).to receive(:latest_merge_request_pipeline?) { true }
        merge_request.merge_train.update!(pipeline: pipeline)
      end

      context 'when the merge request is the first queue' do
        it 'merges the merge request' do
          expect(merge_request).to receive(:cleanup_refs).with(only: :train)
          expect_next_instance_of(MergeRequests::MergeService, project, maintainer, anything) do |service|
            expect(service).to receive(:execute).with(merge_request)
          end

          expect { subject }.to change { MergeTrain.count }.by(-1)
        end

        context 'when it failed to merge the merge request' do
          before do
            allow_any_instance_of(MergeRequests::MergeService).to receive(:execute) { { result: :error } }
          end

          it_behaves_like 'drops the merge request from the merge train' do
            let(:expected_reason) { 'failed to merge' }
          end
        end
      end

      context 'when the merge request is not the first queue' do
        before do
          allow(merge_request.merge_train).to receive(:first_in_train?) { false }
        end

        it 'does not merge the merge request' do
          expect(MergeRequests::MergeService).not_to receive(:new)

          subject
        end
      end
    end
  end
end
