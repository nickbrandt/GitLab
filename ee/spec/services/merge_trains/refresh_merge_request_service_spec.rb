# frozen_string_literal: true

require 'spec_helper'

describe MergeTrains::RefreshMergeRequestService do
  set(:project) { create(:project, :repository) }
  set(:maintainer) { create(:user) }
  let(:service) { described_class.new(project, maintainer, require_recreate: require_recreate) }
  let(:require_recreate) { false }

  before do
    project.add_maintainer(maintainer)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.update!(merge_pipelines_enabled: true)
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
          expect(service).to receive(:abort).with(merge_request, expected_reason, hash_including(process_next: false))
        end

        subject
      end
    end

    shared_examples_for 'creates a pipeline for merge train' do
      let(:previous_ref) { 'refs/heads/master' }

      it do
        expect_next_instance_of(MergeTrains::CreatePipelineService, project, maintainer) do |pipeline_service|
          allow(pipeline_service).to receive(:execute) { { status: :success, pipeline: pipeline } }
          expect(pipeline_service).to receive(:execute).with(merge_request, previous_ref)
        end

        result = subject
        expect(result[:status]).to eq(:success)
        expect(result[:pipeline_created]).to eq(true)
        expect(merge_request.merge_train).to be_fresh
      end
    end

    shared_examples_for 'cancels and recreates a pipeline for the merge train' do
      let(:previous_ref) { 'refs/heads/master' }

      it 'cancels and recreates a pipeline for the merge train', :sidekiq_might_not_need_inline do
        expect_next_instance_of(MergeTrains::CreatePipelineService, project, maintainer) do |pipeline_service|
          allow(pipeline_service).to receive(:execute) { { status: :success, pipeline: create(:ci_pipeline) } }
          expect(pipeline_service).to receive(:execute).with(merge_request, previous_ref)
        end

        result = subject
        new_pipeline = merge_request.merge_train.pipeline
        pipeline.reset

        expect(result[:status]).to eq(:success)
        expect(result[:pipeline_created]).to eq(true)
        expect(pipeline.status).to eq('canceled')
        expect(pipeline.auto_canceled_by_id).to eq(new_pipeline.id)
      end
    end

    shared_examples_for 'does not create a pipeline' do
      it do
        expect(service).not_to receive(:create_pipeline!)

        result = subject
        expect(result[:status]).to eq(:success)
        expect(result[:pipeline_created]).to be_falsy
      end
    end

    context 'when merge pipelines project configuration is disabled' do
      before do
        project.update!(merge_pipelines_enabled: false)
      end

      it_behaves_like 'drops the merge request from the merge train' do
        let(:expected_reason) { 'project disabled merge trains' }
      end

      after do
        project.update!(merge_pipelines_enabled: true)
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

    context 'when merge request is to be squashed' do
      before do
        merge_request.update!(squash: true)
      end

      context 'when merge_train_new_stale_check feature flag is enabled' do
        let(:pipeline) { create(:ci_pipeline) }

        it_behaves_like 'creates a pipeline for merge train'
      end

      context 'when merge_train_new_stale_check feature flag is disabled' do
        before do
          stub_feature_flags(merge_train_new_stale_check: false)
        end

        it_behaves_like 'drops the merge request from the merge train' do
          let(:expected_reason) { 'merge train does not support squash merge' }
        end
      end
    end

    context 'when previous ref is not found' do
      let(:previous_ref) { 'refs/tmp/test' }

      before do
        allow(service).to receive(:previous_ref) { previous_ref }
      end

      it_behaves_like 'drops the merge request from the merge train' do
        let(:expected_reason) { 'previous ref does not exist' }
      end
    end

    context 'when pipeline has not been created yet' do
      context 'when the merge request is the first queue' do
        let(:pipeline) { create(:ci_pipeline) }

        it_behaves_like 'creates a pipeline for merge train'

        context 'when it failed to create a pipeline' do
          before do
            allow_any_instance_of(MergeTrains::CreatePipelineService).to receive(:execute) { { result: :error, message: 'failed to create pipeline' } }
          end

          it_behaves_like 'drops the merge request from the merge train' do
            let(:expected_reason) { 'failed to create pipeline' }
          end
        end
      end
    end

    context 'when pipeline for merge train is running' do
      let(:pipeline) { create(:ci_pipeline, :running, :with_job, project: project, target_sha: previous_ref_sha, source_sha: merge_request.diff_head_sha) }
      let(:previous_ref_sha) { project.repository.commit('refs/heads/master').sha }

      before do
        merge_request.merge_train.update!(pipeline: pipeline)
      end

      context 'when the pipeline is not stale' do
        it_behaves_like 'does not create a pipeline'
      end

      context 'when the pipeline is stale' do
        context 'when merge_train_new_stale_check feature flag is enabled' do
          before do
            merge_request.merge_train.update_column(:status, :stale)
          end

          it_behaves_like 'cancels and recreates a pipeline for the merge train'
        end

        context 'when merge_train_new_stale_check feature flag is disabled' do
          before do
            stub_feature_flags(merge_train_new_stale_check: false)
          end

          let(:previous_ref_sha) { project.repository.commits('refs/heads/master', limit: 2).last.sha }

          it_behaves_like 'cancels and recreates a pipeline for the merge train'
        end
      end

      context 'when the pipeline is required to be recreated' do
        let(:require_recreate) { true }

        it_behaves_like 'cancels and recreates a pipeline for the merge train'
      end
    end

    context 'when pipeline for merge train succeeded' do
      let(:pipeline) { create(:ci_pipeline, :success, target_sha: previous_ref_sha, source_sha: merge_request.diff_head_sha) }
      let(:previous_ref_sha) { project.repository.commit('refs/heads/master').sha }

      before do
        merge_request.merge_train.pipeline = pipeline
        merge_request.merge_params[:sha] = merge_request.diff_head_sha
        merge_request.save
      end

      context 'when the merge request is the first queue' do
        it 'merges the merge request' do
          expect(merge_request).to receive(:cleanup_refs).with(only: :train)
          expect_next_instance_of(MergeRequests::MergeService, project, maintainer, anything) do |service|
            expect(service).to receive(:execute).with(merge_request).and_call_original
          end

          expect { subject }
            .to change { merge_request.merge_train.status }.from('created').to('merged')
        end

        context 'when it failed to merge the merge request' do
          before do
            allow(merge_request).to receive(:mergeable_state?) { true }
            merge_request.update(merge_error: 'Branch has been updated since the merge was requested.')
            allow_any_instance_of(MergeRequests::MergeService).to receive(:execute) { { result: :error } }
          end

          it_behaves_like 'drops the merge request from the merge train' do
            let(:expected_reason) { 'failed to merge. Branch has been updated since the merge was requested.' }
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
