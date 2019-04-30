# frozen_string_literal: true

require 'spec_helper'

describe Security::PipelineVulnerabilitiesFinder do
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
    let(:dast_count) { read_fixture(artifact_dast).dig('site', 'alerts').first['instances'].count }
    let(:ds_count) { read_fixture(artifact_ds)['vulnerabilities'].count }
    let(:sast_count) { read_fixture(artifact_sast)['vulnerabilities'].count }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
    end

    subject { described_class.new(pipeline: pipeline, params: params).execute }

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
          # binding.pry
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

    context 'by all filters' do
      context 'with found entity' do
        let(:params) { { report_type: %w[sast dast container_scanning dependency_scanning] } }

        it 'filters by all params' do
          expect(subject.count).to eq cs_count + dast_count + ds_count + sast_count
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
