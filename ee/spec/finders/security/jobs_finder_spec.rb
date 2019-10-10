# frozen_string_literal: true

require 'spec_helper'

describe Security::JobsFinder do
  let(:pipeline) { create(:ci_pipeline) }
  let(:finder) { described_class.new(pipeline: pipeline, job_types: ::Security::JobsFinder::JOB_TYPES) }

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
        before do
          create(:ci_build, pipeline: pipeline)
        end

        it { is_expected.to be_empty }
      end

      context 'with jobs having report artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { file: 'test.file' } })
        end

        it { is_expected.to be_empty }
      end

      context 'with jobs having non secure report artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'test.file' } } })
        end

        it { is_expected.to be_empty }
      end

      context 'with jobs having report artifacts that are similar to secure artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'report:sast:result.file' } } })
        end

        it { is_expected.to be_empty }
      end

      context 'searching for all types takes precedence over excluding specific types' do
        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline: pipeline, job_types: [:dast]) }

        it { is_expected.to eq([build]) }
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
        before do
          create(:ci_build, :dast, pipeline: create(:ci_pipeline))
        end

        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it 'returns jobs associated with provided pipeline' do
          is_expected.to eq([build])
        end
      end

      context 'with specific secure job types' do
        let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
        let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
        let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline: pipeline, job_types: [:sast, :container_scanning]) }

        it 'returns only those requested' do
          is_expected.to include(sast_build)
          is_expected.to include(container_scanning_build)
          is_expected.not_to include(dast_build)
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
        before do
          create(:ci_build, pipeline: pipeline)
        end

        it { is_expected.to be_empty }
      end

      context 'with jobs having report artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { file: 'test.file' } })
        end

        it { is_expected.to be_empty }
      end

      context 'with jobs having non secure report artifacts' do
        before do
          create(:ci_build, pipeline: pipeline, options: { artifacts: { reports: { file: 'test.file' } } })
        end

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
        before do
          create(:ci_build, :dast, pipeline: create(:ci_pipeline))
        end

        let!(:build) { create(:ci_build, :dast, pipeline: pipeline) }

        it 'returns jobs associated with provided pipeline' do
          is_expected.to eq([build])
        end
      end

      context 'with specific secure job types' do
        let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
        let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
        let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline: pipeline, job_types: [:sast, :container_scanning]) }

        it 'returns only those requested' do
          is_expected.to include(sast_build)
          is_expected.to include(container_scanning_build)
          is_expected.not_to include(dast_build)
        end
      end
    end
  end
end
