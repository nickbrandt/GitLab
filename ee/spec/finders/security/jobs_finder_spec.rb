# frozen_string_literal: true

require 'spec_helper'

describe Security::JobsFinder do
  let(:pipeline) { create(:ci_pipeline) }
  let(:finder) { described_class.new(pipeline) }

  describe '#execute' do
    subject { finder.execute }

    describe 'legacy options stored' do
      before do
        stub_feature_flags(ci_build_metadata_config: false)
      end

      context 'with no jobs' do
        it { is_expected.to be_empty }
      end

      context 'with non secure jobs' do
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        it { is_expected.to be_empty }
      end

      context 'with jobs having report artifacts' do
        let!(:build) { create(:ci_build, pipeline: pipeline, options: { artifacts: { file: 'test.file' } }) }

        it { is_expected.to be_empty }
      end

      context 'with jobs having non secure report artifacts' do
        let!(:build) { create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'test.file' } } }) }

        it { is_expected.to be_empty }
      end

      context 'with jobs having almost secure like report artifacts' do
        let!(:build) { create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'sast.file' } } }) }

        it { is_expected.to be_empty }
      end

      context 'with dast jobs' do
        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with sast jobs' do
        let!(:build) { create(:ci_build, :sast, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with container scanning jobs' do
        let!(:build) { create(:ci_build, :container_scanning, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with dependency scanning jobs' do
        let!(:build) { create(:ci_build, :dependency_scanning, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with many secure pipelines' do
        let!(:another_pipeline) { create(:ci_pipeline) }
        let!(:another_build) { create(:ci_build, :dast, pipeline: another_pipeline) }

        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it 'returns jobs associated with provided pipeline' do
          is_expected.to eq([build])
        end
      end

      context 'with specific secure job types' do
        let!(:build_a) { create(:ci_build, :sast, pipeline: pipeline) }
        let!(:build_b) { create(:ci_build, :container_scanning, pipeline: pipeline) }
        let!(:build_c) { create(:ci_build, :dast, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline, { sast: true, container_scanning: true }) }

        it 'returns only those requested' do
          is_expected.to include(build_a)
          is_expected.to include(build_b)
          is_expected.not_to include(build_c)
        end
      end
    end

    describe 'config options stored' do
      before do
        stub_feature_flags(ci_build_metadata_config: true)
      end

      context 'with no jobs' do
        it { is_expected.to be_empty }
      end

      context 'with non secure jobs' do
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        it { is_expected.to be_empty }
      end

      context 'with jobs having report artifacts' do
        let!(:build) { create(:ci_build, pipeline: pipeline, options: { artifacts: { file: 'test.file' } }) }

        it { is_expected.to be_empty }
      end

      context 'with jobs having non secure report artifacts' do
        let!(:build) { create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'test.file' } } }) }

        it { is_expected.to be_empty }
      end

      context 'with dast jobs' do
        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with sast jobs' do
        let!(:build) { create(:ci_build, :sast, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with container scanning jobs' do
        let!(:build) { create(:ci_build, :container_scanning, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with dependency scanning jobs' do
        let!(:build) { create(:ci_build, :dependency_scanning, pipeline: pipeline) }

        it { is_expected.to eq([build]) }
      end

      context 'with many secure pipelines' do
        let!(:another_pipeline) { create(:ci_pipeline) }
        let!(:another_build) { create(:ci_build, :dast, pipeline: another_pipeline) }

        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it 'returns jobs associated with provided pipeline' do
          is_expected.to eq([build])
        end
      end

      context 'with specific secure job types' do
        let!(:build_a) { create(:ci_build, :sast, pipeline: pipeline) }
        let!(:build_b) { create(:ci_build, :container_scanning, pipeline: pipeline) }
        let!(:build_c) { create(:ci_build, :dast, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline, { sast: true, container_scanning: true }) }

        it 'returns only those requested' do
          is_expected.to include(build_a)
          is_expected.to include(build_b)
          is_expected.not_to include(build_c)
        end
      end
    end
  end
end
