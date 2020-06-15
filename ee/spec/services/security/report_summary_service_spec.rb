# frozen_string_literal: true

require 'spec_helper'

describe Security::ReportSummaryService, '#execute' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  before_all do
    create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :dast, job: job, project: project)
    end
    create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :sast, job: job, project: project)
    end

    create(:ci_build, :success, name: 'cs_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :container_scanning, job: job, project: project)
    end
    create(:ci_build, :success, name: 'ds_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: project)
    end

    create_security_scan(project, pipeline, 'dast', 34)
    create_security_scan(project, pipeline, 'sast', 12)
  end

  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
  end

  let(:result) do
    described_class.new(
      pipeline,
      selection_information
    ).execute
  end

  context 'Some fields are requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count, :vulnerabilities_count],
        container_scanning: [:vulnerabilities_count]
      }
    end

    it 'returns only the request fields' do
      expect(result).to eq({
        dast: { scanned_resources_count: 34, vulnerabilities_count: 20 },
        container_scanning: { vulnerabilities_count: 8 }
      })
    end
  end

  context 'When some fields are not requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count]
      }
    end

    it 'does not make needless queries' do
      expect(::Security::VulnerabilityCountingService).not_to receive(:new)

      expect_next_instance_of(::Security::ScannedResourcesCountingService, anything, ['dast']) do |service|
        expect(service).to receive(:execute).and_return({})
      end

      result
    end
  end

  context 'All fields are requested' do
    let(:selection_information) do
      {
        dast: [:scanned_resources_count, :vulnerabilities_count],
        sast: [:scanned_resources_count, :vulnerabilities_count],
        container_scanning: [:scanned_resources_count, :vulnerabilities_count],
        dependency_scanning: [:scanned_resources_count, :vulnerabilities_count]
      }
    end

    it 'returns the scanned_resources_count' do
      expect(result).to match(a_hash_including(
                                dast: a_hash_including(scanned_resources_count: 34),
                                sast: a_hash_including(scanned_resources_count: 12),
                                container_scanning: a_hash_including(scanned_resources_count: 0),
                                dependency_scanning: a_hash_including(scanned_resources_count: 0)
                              ))
    end

    it 'returns the vulnerability count' do
      expect(result).to match(a_hash_including(
                                dast: a_hash_including(vulnerabilities_count: 20),
                                sast: a_hash_including(vulnerabilities_count: 33),
                                container_scanning: a_hash_including(vulnerabilities_count: 8),
                                dependency_scanning: a_hash_including(vulnerabilities_count: 4)
                              ))
    end

    context 'When ran no security scans' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it 'returns 0 vulnerabilities' do
        expect(result[:dast][:vulnerabilities_count]).to be(0)
      end

      it 'returns 0 scanned resources' do
        expect(result[:dast][:scanned_resources_count]).to be(0)
      end
    end
  end
end

def create_security_scan(project, pipeline, report_type, scanned_resources_count)
  dast_build = create(:ee_ci_build, :artifacts, project: project, pipeline: pipeline, name: report_type)
  create(:security_scan, scan_type: report_type, scanned_resources_count: scanned_resources_count, build: dast_build)
end
