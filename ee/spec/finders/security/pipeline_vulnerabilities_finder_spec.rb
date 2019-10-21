# frozen_string_literal: true

require 'spec_helper'

describe Security::PipelineVulnerabilitiesFinder do
  class NoDeduplicationMergeReportsService
    def initialize(*source_reports)
      @source_reports = source_reports
    end

    def execute
      @source_reports.last
    end
  end

  def disable_deduplication
    allow(::Security::MergeReportsService).to receive(:new) do |*args|
      NoDeduplicationMergeReportsService.new(*args)
    end
  end

  describe '#execute' do
    set(:project) { create(:project, :repository) }
    set(:pipeline) { create(:ci_pipeline, :success, project: project) }

    set(:build_cs) { create(:ci_build, :success, name: 'cs_job', pipeline: pipeline, project: project) }
    set(:build_dast) { create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) }
    set(:build_ds) { create(:ci_build, :success, name: 'ds_job', pipeline: pipeline, project: project) }
    set(:build_sast) { create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) }

    set(:artifact_cs) { create(:ee_ci_job_artifact, :container_scanning, job: build_cs, project: project) }
    set(:artifact_dast) { create(:ee_ci_job_artifact, :dast, job: build_dast, project: project) }
    set(:artifact_ds) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds, project: project) }
    set(:artifact_sast) { create(:ee_ci_job_artifact, :sast, job: build_sast, project: project) }

    let(:cs_count) { read_fixture(artifact_cs)['unapproved'].count }
    let(:ds_count) { read_fixture(artifact_ds)['vulnerabilities'].count }
    let(:sast_count) { read_fixture(artifact_sast)['vulnerabilities'].count }
    let(:dast_count) do
      read_fixture(artifact_dast)['site'].sum do |site|
        site['alerts'].sum do |alert|
          alert['instances'].size
        end
      end
    end

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
      # Stub out deduplication, if not done the expectations will vary based on the fixtures (which may/may not have duplicates)
      disable_deduplication
    end

    subject { described_class.new(pipeline: pipeline, params: params).execute }

    context 'by order' do
      let(:params) { { report_type: %w[sast] } }
      let!(:occurrence1) { build(:vulnerabilities_occurrence, confidence: Vulnerabilities::Occurrence::CONFIDENCE_LEVELS[:high],   severity: Vulnerabilities::Occurrence::SEVERITY_LEVELS[:high]) }
      let!(:occurrence2) { build(:vulnerabilities_occurrence, confidence: Vulnerabilities::Occurrence::CONFIDENCE_LEVELS[:medium], severity: Vulnerabilities::Occurrence::SEVERITY_LEVELS[:critical]) }
      let!(:occurrence3) { build(:vulnerabilities_occurrence, confidence: Vulnerabilities::Occurrence::CONFIDENCE_LEVELS[:high],   severity: Vulnerabilities::Occurrence::SEVERITY_LEVELS[:critical]) }
      let!(:res) { [occurrence3, occurrence2, occurrence1] }

      it 'orders by severity and confidence' do
        allow_any_instance_of(described_class).to receive(:filter).and_return(res)

        expect(subject).to eq([occurrence3, occurrence2, occurrence1])
      end
    end

    context 'by report type' do
      context 'when sast' do
        let(:params) { { report_type: %w[sast] } }

        it 'includes only sast' do
          expect(subject.count).to eq sast_count
        end
      end

      context 'when dependency_scanning' do
        let(:params) { { report_type: %w[dependency_scanning] } }

        it 'includes only dependency_scanning' do
          expect(subject.count).to eq ds_count
        end
      end

      context 'when dast' do
        let(:params) { { report_type: %w[dast] } }

        it 'includes only dast' do
          expect(subject.count).to eq dast_count
        end
      end

      context 'when container_scanning' do
        let(:params) { { report_type: %w[container_scanning] } }

        it 'includes only container_scanning' do
          expect(subject.count).to eq cs_count
        end
      end
    end

    context 'by scope' do
      let(:ds_occurrence) { pipeline.security_reports.reports["dependency_scanning"].occurrences.first }
      let(:sast_occurrence) { pipeline.security_reports.reports["sast"].occurrences.first }

      let!(:feedback) do
        [
          create(
            :vulnerability_feedback,
            :dismissal,
            :dependency_scanning,
            project: project,
            pipeline: pipeline,
            project_fingerprint: ds_occurrence.project_fingerprint,
            vulnerability_data: ds_occurrence.raw_metadata
          ),
          create(
            :vulnerability_feedback,
            :dismissal,
            :sast,
            project: project,
            pipeline: pipeline,
            project_fingerprint: sast_occurrence.project_fingerprint,
            vulnerability_data: sast_occurrence.raw_metadata
          )
        ]
      end

      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns non-dismissed vulnerabilities' do
          expect(subject.count).to eq cs_count + dast_count + ds_count + sast_count - feedback.count
          expect(subject.map(&:project_fingerprint)).not_to include(*feedback.map(&:project_fingerprint))
        end
      end

      context 'when `dismissed`' do
        subject { described_class.new(pipeline: pipeline, params: { report_type: %w[dependency_scanning], scope: 'dismissed' } ).execute }

        it 'returns non-dismissed vulnerabilities' do
          expect(subject.count).to eq(ds_count - 1)
          expect(subject.map(&:project_fingerprint)).not_to include(ds_occurrence.project_fingerprint)
        end
      end

      context 'when `all`' do
        let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning], scope: 'all' } }

        it 'returns all vulnerabilities' do
          expect(subject.count).to eq cs_count + dast_count + ds_count + sast_count
        end
      end
    end

    context 'by severity' do
      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns all vulnerability severity levels' do
          expect(subject.map(&:severity).uniq).to match_array %w[undefined unknown low medium high critical info]
        end
      end

      context 'when `low`' do
        subject { described_class.new(pipeline: pipeline, params: { severity: 'low' } ).execute }

        it 'returns only low-severity vulnerabilities' do
          expect(subject.map(&:severity).uniq).to match_array %w[low]
        end
      end
    end

    context 'by confidence' do
      context 'when unscoped' do
        subject { described_class.new(pipeline: pipeline).execute }

        it 'returns all vulnerability confidence levels' do
          expect(subject.map(&:confidence).uniq).to match_array %w[undefined unknown low medium high]
        end
      end

      context 'when `medium`' do
        subject { described_class.new(pipeline: pipeline, params: { confidence: 'medium' } ).execute }

        it 'returns only medium-confidence vulnerabilities' do
          expect(subject.map(&:confidence).uniq).to match_array %w[medium]
        end
      end
    end

    context 'by all filters' do
      context 'with found entity' do
        let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning], scope: 'all' } }

        it 'filters by all params' do
          expect(subject.count).to eq cs_count + dast_count + ds_count + sast_count
          expect(subject.map(&:confidence).uniq).to match_array %w[undefined unknown low medium high]
          expect(subject.map(&:severity).uniq).to match_array %w[undefined unknown low medium high critical info]
        end
      end

      context 'without found entity' do
        let(:params) { { report_type: %w[code_quality] } }

        it 'did not find anything' do
          is_expected.to be_empty
        end
      end
    end

    context 'without params' do
      subject { described_class.new(pipeline: pipeline).execute }

      it 'returns all report_types' do
        expect(subject.count).to eq cs_count + dast_count + ds_count + sast_count
      end
    end

    def read_fixture(fixture)
      JSON.parse(File.read(fixture.file.path))
    end
  end
end
