# frozen_string_literal: true

require 'spec_helper'

describe AutoMerge::AddToMergeTrainWhenPipelineSucceedsService do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  let(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master')
  end

  let(:pipeline) { merge_request.reload.all_pipelines.first }

  before do
    stub_licensed_features(merge_trains: true, merge_pipelines: true)
    project.add_maintainer(user)
    project.update!(merge_pipelines_enabled: true)
    allow(AutoMergeProcessWorker).to receive(:perform_async) { }
    merge_request.update_head_pipeline
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    it 'enables auto merge' do
      expect(SystemNoteService)
        .to receive(:add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user, merge_request.actual_head_pipeline.sha)

      subject

      expect(merge_request).to be_auto_merge_enabled
    end
  end

  describe '#process' do
    subject { service.process(merge_request) }

    context 'when the latest pipeline in the merge request has succeeded' do
      before do
        pipeline.succeed!
      end

      it 'executes MergeTrainService' do
        expect_next_instance_of(AutoMerge::MergeTrainService) do |train_service|
          expect(train_service).to receive(:execute).with(merge_request)
        end

        subject
      end

      context 'when merge train strategy is not available for the merge request' do
        before do
          train_service = double
          allow(train_service).to receive(:available_for?) { false }
          allow(AutoMerge::MergeTrainService).to receive(:new) { train_service }
        end

        it 'aborts auto merge' do
          expect(service).to receive(:abort).once

          subject
        end
      end
    end

    context 'when the latest pipeline in the merge request is running' do
      it 'does not initialize MergeTrainService' do
        expect(AutoMerge::MergeTrainService).not_to receive(:new)

        subject
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request) }

    let(:merge_request) { create(:merge_request, :add_to_merge_train_when_pipeline_succeeds, merge_user: user) }

    it 'cancels auto merge' do
      expect(SystemNoteService)
        .to receive(:cancel_add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user)

      subject

      expect(merge_request).not_to be_auto_merge_enabled
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, 'an error') }

    let(:merge_request) { create(:merge_request, :add_to_merge_train_when_pipeline_succeeds, merge_user: user) }

    it 'aborts auto merge' do
      expect(SystemNoteService)
        .to receive(:abort_add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user, 'an error')

      subject

      expect(merge_request).not_to be_auto_merge_enabled
    end
  end

  describe '#available_for?' do
    subject { service.available_for?(merge_request) }

    it { is_expected.to eq(true) }

    context 'when merge trains option is disabled' do
      before do
        expect(merge_request.project).to receive(:merge_trains_enabled?) { false }
      end

      it { is_expected.to eq(false) }
    end

    context 'when merge request is submitted from a forked project' do
      before do
        allow(merge_request).to receive(:for_fork?) { true }
      end

      it { is_expected.to eq(false) }
    end

    context 'when the latest pipeline in the merge request is not active' do
      before do
        pipeline.succeed!
      end

      it { is_expected.to eq(false) }
    end

    context 'when merge request is not mergeable' do
      before do
        merge_request.update!(title: merge_request.wip_title)
      end

      it { is_expected.to eq(false) }
    end
  end
end
