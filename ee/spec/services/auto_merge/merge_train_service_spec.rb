# frozen_string_literal: true

require 'spec_helper'

describe AutoMerge::MergeTrainService do
  include ExclusiveLeaseHelpers

  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:service) { described_class.new(project, user, params) }
  let(:params) { {} }

  let(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, target_project: project)
  end

  before do
    project.add_maintainer(user)

    allow(AutoMergeProcessWorker).to receive(:perform_async) { }

    stub_licensed_features(merge_trains: true, merge_pipelines: true)
    project.update!(merge_pipelines_enabled: true)
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    it 'enables auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request.auto_merge_enabled).to be_truthy
      expect(merge_request.merge_user).to eq(user)
      expect(merge_request.auto_merge_strategy).to eq(AutoMergeService::STRATEGY_MERGE_TRAIN)
    end

    it 'creates merge train' do
      subject

      merge_request.reload
      expect(merge_request.merge_train).to be_present
      expect(merge_request.merge_train.user).to eq(user)
    end

    it 'creates system note' do
      expect(SystemNoteService)
        .to receive(:merge_train).with(merge_request, project, user, instance_of(MergeTrain))

      subject
    end

    it 'returns result code' do
      is_expected.to eq(:merge_train)
    end

    context 'when failed to save the record' do
      before do
        allow(merge_request).to receive(:save) { false }
      end

      it 'returns result code' do
        is_expected.to eq(:failed)
      end
    end
  end

  describe '#process' do
    subject { service.process(merge_request) }

    let(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    it 'calls RefreshMergeRequestsService' do
      expect_next_instance_of(MergeTrains::RefreshMergeRequestsService) do |service|
        expect(service).to receive(:execute).with(merge_request)
      end

      subject
    end

    context 'when merge request is not on a merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'does not call RefreshMergeRequestsService' do
        expect(MergeTrains::RefreshMergeRequestsService).not_to receive(:new)

        subject
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request, **params) }

    let(:params) { {} }

    let!(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    it 'cancels auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request).not_to be_auto_merge_enabled
      expect(merge_request.merge_user).to be_nil
      expect(merge_request.merge_params).not_to include('should_remove_source_branch')
      expect(merge_request.merge_params).not_to include('commit_message')
      expect(merge_request.merge_params).not_to include('squash_commit_message')
      expect(merge_request.merge_params).not_to include('auto_merge_strategy')
      expect(merge_request.merge_train).not_to be_present
    end

    it 'writes system note to the merge request' do
      expect(SystemNoteService)
        .to receive(:cancel_merge_train).with(merge_request, project, user)

      subject
    end

    context 'when pipeline exists' do
      before do
        merge_request.merge_train.update!(pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline) }
      let(:build) { create(:ci_build, :running, pipeline: pipeline) }

      it 'cancels the jobs in the pipeline' do
        expect { subject }.to change { build.reload.status }.from('running').to('canceled')
      end
    end

    context 'when train ref exists' do
      before do
        merge_request.project.repository.create_ref(merge_request.target_branch, merge_request.train_ref_path)
      end

      it 'deletes train ref' do
        expect { subject }
          .to change { merge_request.project.repository.ref_exists?(merge_request.train_ref_path) }
          .from(true).to(false)
      end
    end

    context 'when train ref does not exist' do
      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the other merge request is following the merge request' do
      let!(:merge_request_2) do
        create(:merge_request, :on_train,
          source_project: project, source_branch: 'signed-commits',
          target_project: project, target_branch: 'master')
      end

      it 'processes the next merge request on the train by default' do
        expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request_2.id)

        subject

        expect(merge_request_2.reset.merge_train).to be_stale
      end
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, 'an error', **args) }

    let!(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    let(:args) { {} }

    it 'aborts auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request).not_to be_auto_merge_enabled
      expect(merge_request.merge_user).to be_nil
      expect(merge_request.merge_params).not_to include('should_remove_source_branch')
      expect(merge_request.merge_params).not_to include('commit_message')
      expect(merge_request.merge_params).not_to include('squash_commit_message')
      expect(merge_request.merge_params).not_to include('auto_merge_strategy')
      expect(merge_request.merge_train).not_to be_present
    end

    it 'writes system note to the merge request' do
      expect(SystemNoteService)
        .to receive(:abort_merge_train).with(merge_request, project, user, 'an error')

      subject
    end

    context 'when the other merge request is following the merge request' do
      let!(:merge_request_2) do
        create(:merge_request, :on_train,
          source_project: project, source_branch: 'signed-commits',
          target_project: project, target_branch: 'master')
      end

      it 'processes the next merge request on the train' do
        expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request_2.id)

        subject

        expect(merge_request_2.reset.merge_train).to be_stale
      end

      context 'when process_next is false' do
        let(:args) { { process_next: false } }

        it 'does not process the next merge request on the train' do
          expect(AutoMergeProcessWorker).not_to receive(:perform_async)

          subject
        end
      end
    end
  end

  describe '#available_for?' do
    subject { service.available_for?(merge_request) }

    let(:pipeline) { double }

    before do
      allow(merge_request).to receive(:mergeable_state?) { true }
      allow(merge_request).to receive(:for_fork?) { false }
      allow(merge_request).to receive(:actual_head_pipeline) { pipeline }
      allow(pipeline).to receive(:complete?) { true }
    end

    it { is_expected.to be_truthy }

    context 'when merge trains project option is disabled' do
      before do
        stub_feature_flags(merge_trains_enabled: false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when merge request is not mergeable' do
      before do
        allow(merge_request).to receive(:mergeable_state?) { false }
      end

      it { is_expected.to be_falsy }
    end

    context 'when merge request is submitted from a forked project' do
      before do
        allow(merge_request).to receive(:for_fork?) { true }
      end

      it { is_expected.to be_falsy }
    end

    context 'when the head pipeline of the merge request has not finished' do
      before do
        allow(pipeline).to receive(:complete?) { false }
      end

      it { is_expected.to be_falsy }
    end
  end

  def create_pipeline_for(merge_request)
    MergeRequests::CreatePipelineService.new(project, user).execute(merge_request)
  end
end
