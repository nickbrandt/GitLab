# frozen_string_literal: true

require 'rails_helper'

describe 'Two merge requests on a merge train' do
  let(:project) { create(:project, :repository) }
  set(:maintainer_1) { create(:user) }
  set(:maintainer_2) { create(:user) }

  let(:merge_request_1) do
    create(:merge_request,
      source_branch: 'feature', source_project: project,
      target_branch: 'master', target_project: project,
      merge_status: 'unchecked')
  end

  let(:merge_request_2) do
    create(:merge_request,
      source_branch: 'signed-commits', source_project: project,
      target_branch: 'master', target_project: project,
      merge_status: 'unchecked')
  end

  let(:ci_yaml) do
    { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
  end

  before do
    project.add_maintainer(maintainer_1)
    project.add_maintainer(maintainer_2)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))

    head_pipeline = double('Ci::Pipeline')
    allow(head_pipeline).to receive(:complete?) { true }
    allow(merge_request_1).to receive(:actual_head_pipeline) { head_pipeline }
    allow(merge_request_2).to receive(:actual_head_pipeline) { head_pipeline }

    AutoMergeService.new(project, maintainer_1)
      .execute(merge_request_1, AutoMergeService::STRATEGY_MERGE_TRAIN)
    AutoMergeService.new(project, maintainer_2)
      .execute(merge_request_2, AutoMergeService::STRATEGY_MERGE_TRAIN)

    merge_request_1.reload
    merge_request_2.reload
  end

  it 'creates a pipeline for merge request 1' do
    expect(merge_request_1.merge_train.pipeline).to be_merge_request_pipeline
    expect(merge_request_1.merge_train.pipeline.user).to eq(maintainer_1)
  end

  it 'does not create a pipeline for merge request 2' do
    expect(merge_request_2.merge_train.pipeline).to be_nil
  end

  it 'does not merge anything yet' do
    expect(merge_request_1).to be_opened
    expect(merge_request_2).to be_opened
  end

  context 'when the pipeline for merge request 1 succeeded' do
    before do
      merge_request_1.merge_train.pipeline.succeed!

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'merges merge request 1' do
      expect(merge_request_1).to be_merged
      expect(merge_request_1.metrics.merged_by).to eq(maintainer_1)
    end

    it 'removes merge request 1 from the merge train' do
      expect(merge_request_1.merge_train).to be_nil
    end

    it 'creates a pipeline for merge request 2' do
      expect(merge_request_2.merge_train.pipeline).to be_merge_request_pipeline
      expect(merge_request_2.merge_train.pipeline.user).to eq(maintainer_2)
    end

    context 'when the pipeline for merge request 2 succeeded' do
      before do
        merge_request_2.merge_train.pipeline.succeed!

        merge_request_2.reload
      end

      it 'merges merge request 2' do
        expect(merge_request_2).to be_merged
        expect(merge_request_2.metrics.merged_by).to eq(maintainer_2)
      end

      it 'removes merge request 2 from the merge train' do
        expect(merge_request_2.merge_train).to be_nil
      end
    end
  end

  context 'when the pipeline for merge request 1 failed' do
    before do
      merge_request_1.merge_train.pipeline.drop!

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'does not merges merge request 1' do
      expect(merge_request_1).to be_opened
    end

    it 'drops merge request 1 from the merge train' do
      expect(merge_request_1.merge_train).to be_nil
      expect(merge_request_1.notes.last.note).to eq('removed this merge request from the merge train because pipeline did not succeed')
    end

    it 'creates a pipeline for merge request 2' do
      expect(merge_request_2.merge_train.pipeline).to be_merge_request_pipeline
      expect(merge_request_2.merge_train.pipeline.user).to eq(maintainer_2)
    end
  end

  context 'when merge request 1 is canceled by a user' do
    before do
      AutoMergeService.new(project, maintainer_1).cancel(merge_request_1)

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'drops merge request 1 from the merge train' do
      expect(merge_request_1.merge_train).to be_nil
      expect(merge_request_1.notes.last.note).to eq('removed this merge request from the merge train')
    end

    it 'creates a pipeline for merge request 2' do
      expect(merge_request_2.merge_train.pipeline).to be_merge_request_pipeline
      expect(merge_request_2.merge_train.pipeline.user).to eq(maintainer_2)
    end
  end

  context 'when merge request 1 is not mergeable' do
    before do
      merge_request_1.update!(title: merge_request_1.wip_title)
      merge_request_1.merge_train.pipeline.succeed!

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'drops merge request 1 from the merge train' do
      expect(merge_request_1.merge_train).to be_nil
      expect(merge_request_1.notes.last.note).to eq('removed this merge request from the merge train because merge request is not mergeable')
    end

    it 'creates a pipeline for merge request 2' do
      expect(merge_request_2.merge_train.pipeline).to be_merge_request_pipeline
      expect(merge_request_2.merge_train.pipeline.user).to eq(maintainer_2)
    end
  end

  context 'when merge trains option is disabled' do
    before do
      project.update!(merge_trains_enabled: false)
      merge_request_1.merge_train.pipeline.succeed!

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'drops merge request 1 from the merge train' do
      expect(merge_request_1.merge_train).to be_nil
      expect(merge_request_1.notes.last.note).to eq('removed this merge request from the merge train because project disabled merge trains')
    end

    it 'drops merge request 2 from the merge train' do
      expect(merge_request_2.merge_train).to be_nil
      expect(merge_request_2.notes.last.note).to eq('removed this merge request from the merge train because project disabled merge trains')
    end

    after do
      project.update!(merge_trains_enabled: true)
    end
  end
end
