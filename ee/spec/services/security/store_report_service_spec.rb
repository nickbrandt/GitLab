# frozen_string_literal: true

require 'spec_helper'

describe Security::StoreReportService, '#execute' do
  let(:user) { create(:user) }
  let(:artifact) { create(:ee_ci_job_artifact, report_type) }
  let(:project) { artifact.project }
  let(:pipeline) { artifact.job.pipeline }
  let(:report) { pipeline.security_reports.get_report(report_type.to_s, artifact) }

  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, security_dashboard: true)
  end

  subject { described_class.new(pipeline, report).execute }

  context 'without existing data' do
    before do
      project.add_developer(user)
      allow(pipeline).to receive(:user).and_return(user)
    end

    using RSpec::Parameterized::TableSyntax

    where(:case_name, :report_type, :scanners, :identifiers, :occurrences, :occurrence_identifiers, :occurrence_pipelines) do
      'with SAST report'                | :sast                | 3 | 17 | 33 | 39 | 33
      'with Dependency Scanning report' | :dependency_scanning | 2 | 7  | 4  | 7  | 4
      'with Container Scanning report'  | :container_scanning  | 1 | 8  | 8  | 8  | 8
    end

    with_them do
      it 'inserts all scanners' do
        expect { subject }.to change { Vulnerabilities::Scanner.count }.by(scanners)
      end

      it 'inserts all identifiers' do
        expect { subject }.to change { Vulnerabilities::Identifier.count }.by(identifiers)
      end

      it 'inserts all occurrences' do
        expect { subject }.to change { Vulnerabilities::Occurrence.count }.by(occurrences)
      end

      it 'inserts all occurrence identifiers (join model)' do
        expect { subject }.to change { Vulnerabilities::OccurrenceIdentifier.count }.by(occurrence_identifiers)
      end

      it 'inserts all occurrence pipelines (join model)' do
        expect { subject }.to change { Vulnerabilities::OccurrencePipeline.count }.by(occurrence_pipelines)
      end

      it 'inserts all vulnerabilties' do
        expect { subject }.to change { Vulnerability.count }.by(occurrences)
      end
    end
  end

  context 'with existing data from previous pipeline' do
    let(:scanner) { create(:vulnerabilities_scanner, project: project, external_id: 'bandit', name: 'Bandit') }
    let(:identifier) { create(:vulnerabilities_identifier, project: project, fingerprint: 'e6dd15eda2137be0034977a85b300a94a4f243a3') }
    let!(:new_artifact) { create(:ee_ci_job_artifact, :sast, job: new_build) }
    let(:new_build) { create(:ci_build, pipeline: new_pipeline) }
    let(:new_pipeline) { create(:ci_pipeline, project: project) }
    let(:new_report) { new_pipeline.security_reports.get_report(report_type.to_s, artifact) }
    let(:report_type) { :sast }

    let!(:occurrence) do
      create(:vulnerabilities_occurrence,
        pipelines: [pipeline],
        identifiers: [identifier],
        primary_identifier: identifier,
        scanner: scanner,
        project: project,
        location_fingerprint: 'd869ba3f0b3347eb2749135a437dc07c8ae0f420')
    end

    before do
      project.add_developer(user)
      allow(new_pipeline).to receive(:user).and_return(user)
    end

    subject { described_class.new(new_pipeline, new_report).execute }

    it 'inserts only new scanners and reuse existing ones' do
      expect { subject }.to change { Vulnerabilities::Scanner.count }.by(2)
    end

    it 'inserts only new identifiers and reuse existing ones' do
      expect { subject }.to change { Vulnerabilities::Identifier.count }.by(16)
    end

    it 'inserts only new occurrences and reuse existing ones' do
      expect { subject }.to change { Vulnerabilities::Occurrence.count }.by(32)
    end

    it 'inserts all occurrence pipelines (join model) for this new pipeline' do
      expect { subject }.to change { Vulnerabilities::OccurrencePipeline.where(pipeline: new_pipeline).count }.by(33)
    end
  end

  context 'with existing data from same pipeline' do
    let!(:occurrence) { create(:vulnerabilities_occurrence, project: project, pipelines: [pipeline]) }
    let(:report_type) { :sast }

    it 'skips report' do
      expect(subject).to eq({
        status: :error,
        message: "sast report already stored for this pipeline, skipping..."
      })
    end
  end
end
