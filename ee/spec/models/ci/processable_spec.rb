# frozen_string_literal: true

require 'spec_helper'

describe Ci::Processable do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:detached_merge_request_pipeline) do
    create(:ci_pipeline, :detached_merge_request_pipeline, :with_job, project: project)
  end

  let_it_be(:legacy_detached_merge_request_pipeline) do
    create(:ci_pipeline, :legacy_detached_merge_request_pipeline, :with_job, project: project)
  end

  let_it_be(:merged_result_pipeline) do
    create(:ci_pipeline, :merged_result_pipeline, :with_job, project: project)
  end

  describe '#merge_train_pipeline?' do
    subject { pipeline.processables.first.merge_train_pipeline? }

    context 'in a detached merge request pipeline' do
      let(:pipeline) { detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_train_pipeline?) }
    end

    context 'in a legacy detached merge_request_pipeline' do
      let(:pipeline) { legacy_detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_train_pipeline?) }
    end

    context 'in a pipeline for merged results' do
      let(:pipeline) { merged_result_pipeline }

      it { is_expected.to eq(pipeline.merge_train_pipeline?) }
    end
  end
end
