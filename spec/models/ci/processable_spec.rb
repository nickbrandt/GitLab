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

  describe '#aggregated_needs_names' do
    let(:with_aggregated_needs) { pipeline.processables.select_with_aggregated_needs(project) }

    context 'with created status' do
      let!(:processable) { create(:ci_build, :created, project: project, pipeline: pipeline) }

      context 'with needs' do
        before do
          create(:ci_build_need, build: processable, name: 'test1')
          create(:ci_build_need, build: processable, name: 'test2')
        end

        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns all needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to contain_exactly('test1', 'test2')
        end
      end

      context 'without needs' do
        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns empty needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to be_nil
        end
      end
    end
  end

  describe 'validate presence of scheduling_type' do
    using RSpec::Parameterized::TableSyntax

    subject { build(:ci_build, project: project, pipeline: pipeline, importing: importing) }

    where(:importing, :validate_scheduling_type_flag, :should_validate) do
      false | true  | true
      false | false | false
      true  | true  | false
      true  | false | false
    end

    with_them do
      before do
        stub_feature_flags(validate_scheduling_type_of_processables: validate_scheduling_type_flag)
      end

      context 'on create' do
        it 'validates presence' do
          if should_validate
            is_expected.to validate_presence_of(:scheduling_type).on(:create)
          else
            is_expected.not_to validate_presence_of(:scheduling_type).on(:create)
          end
        end
      end

      context 'on update' do
        it { is_expected.not_to validate_presence_of(:scheduling_type).on(:update) }
      end
    end
  end

  describe '.populate_scheduling_type!' do
    let!(:build_without_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:build_with_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:needs_relation) { create(:ci_build_need, build: build_with_needs) }
    let!(:another_build) { create(:ci_build, project: project) }

    before do
      Ci::Processable.update_all(scheduling_type: nil)
    end

    it 'populates scheduling_type of processables' do
      expect do
        pipeline.processables.populate_scheduling_type!
      end.to change(pipeline.processables.where(scheduling_type: nil), :count).from(2).to(0)

      expect(build_without_needs.reload.scheduling_type).to eq('stage')
      expect(build_with_needs.reload.scheduling_type).to eq('dag')
    end

    it 'does not affect processables from other pipelines' do
      pipeline.processables.populate_scheduling_type!
      expect(another_build.reload.scheduling_type).to be_nil
    end
  end

  describe '#needs_attributes' do
    let(:build) { create(:ci_build, :created, project: project, pipeline: pipeline) }

    subject { build.needs_attributes }

    context 'with needs' do
      before do
        create(:ci_build_need, build: build, name: 'test1')
        create(:ci_build_need, build: build, name: 'test2')
      end

      it 'returns all needs attributes' do
        is_expected.to contain_exactly(
          { 'artifacts' => true, 'name' => 'test1' },
          { 'artifacts' => true, 'name' => 'test2' }
        )
      end
    end

    context 'without needs' do
      it { is_expected.to be_empty }
    end
  end

  describe '#merge_request?' do
    subject { pipeline.processables.first.merge_request? }

    context 'in a detached merge request pipeline' do
      let(:pipeline) { detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_request?) }
    end

    context 'in a legacy detached merge_request_pipeline' do
      let(:pipeline) { legacy_detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_request?) }
    end

    context 'in a pipeline for merged results' do
      let(:pipeline) { merged_result_pipeline }

      it { is_expected.to eq(pipeline.merge_request?) }
    end
  end

  describe '#merge_request_ref?' do
    subject { pipeline.processables.first.merge_request_ref? }

    context 'in a detached merge request pipeline' do
      let(:pipeline) { detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_request_ref?) }
    end

    context 'in a legacy detached merge_request_pipeline' do
      let(:pipeline) { legacy_detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.merge_request_ref?) }
    end

    context 'in a pipeline for merged results' do
      let(:pipeline) { merged_result_pipeline }

      it { is_expected.to eq(pipeline.merge_request_ref?) }
    end
  end

  describe '#legacy_detached_merge_request_pipeline?' do
    subject { pipeline.processables.first.legacy_detached_merge_request_pipeline? }

    context 'in a detached merge request pipeline' do
      let(:pipeline) { detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.legacy_detached_merge_request_pipeline?) }
    end

    context 'in a legacy detached merge_request_pipeline' do
      let(:pipeline) { legacy_detached_merge_request_pipeline }

      it { is_expected.to eq(pipeline.legacy_detached_merge_request_pipeline?) }
    end

    context 'in a pipeline for merged results' do
      let(:pipeline) { merged_result_pipeline }

      it { is_expected.to eq(pipeline.legacy_detached_merge_request_pipeline?) }
    end
  end
end
