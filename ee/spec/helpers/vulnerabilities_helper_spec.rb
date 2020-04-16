# frozen_string_literal: true

require 'spec_helper'

describe VulnerabilitiesHelper do
  let_it_be(:user) { build(:user) }
  let_it_be(:vulnerability) { create(:vulnerability, :with_findings, title: "My vulnerability") }
  let_it_be(:finding) { vulnerability.finding }
  let(:vulnerability_serializer_hash) do
    vulnerability.slice(
      :id,
      :title,
      :state,
      :severity,
      :confidence,
      :report_type,
      :resolved_on_default_branch,
      :project_default_branch,
      :resolved_by_id,
      :dismissed_by_id,
      :confirmed_by_id
    )
  end
  let(:occurrence_serializer_hash) do
    finding.slice(:description,
      :identifiers,
      :links,
      :location,
      :name,
      :issue_feedback,
      :project,
      :solution
    )
  end

  before do
    allow(helper).to receive(:can?).and_return(true)
    allow(helper).to receive(:current_user).and_return(user)
  end

  RSpec.shared_examples 'vulnerability properties' do
    before do
      vulnerability_serializer_stub = instance_double("VulnerabilitySerializer")
      expect(VulnerabilitySerializer).to receive(:new).and_return(vulnerability_serializer_stub)
      expect(vulnerability_serializer_stub).to receive(:represent).with(vulnerability).and_return(vulnerability_serializer_hash)

      occurrence_serializer_stub = instance_double("Vulnerabilities::OccurrenceSerializer")
      expect(Vulnerabilities::OccurrenceSerializer).to receive(:new).and_return(occurrence_serializer_stub)
      expect(occurrence_serializer_stub).to receive(:represent).with(finding).and_return(occurrence_serializer_hash)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    it 'has expected vulnerability properties' do
      expect(subject).to include(
        vulnerability_json: kind_of(String),
        project_fingerprint: vulnerability.finding.project_fingerprint,
        create_issue_url: kind_of(String),
        has_mr: anything,
        vulnerability_feedback_help_path: kind_of(String),
        finding_json: kind_of(String),
        timestamp: Time.now.to_i
      )
    end
  end

  describe '#vulnerability_data' do
    subject { helper.vulnerability_data(vulnerability, pipeline) }

    describe 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:pipelineData) { JSON.parse(subject[:pipeline_json]) }

      include_examples 'vulnerability properties'

      it 'returns expected pipeline data' do
        expect(pipelineData).to include(
          'id' => pipeline.id,
          'created_at' => pipeline.created_at.iso8601,
          'url' => be_present
        )
      end
    end

    describe 'when pipeline is nil' do
      let(:pipeline) { nil }

      include_examples 'vulnerability properties'

      it 'returns no pipeline data' do
        expect(subject[:pipeline]).to be_nil
      end
    end
  end

  describe '#vulnerability_finding_data' do
    let(:finding) { build(:vulnerabilities_occurrence) }

    subject { helper.vulnerability_finding_data(finding) }

    it 'returns finding information' do
      expect(subject).to match(
        description: finding.description,
        identifiers: kind_of(Array),
        issue_feedback: anything,
        links: finding.links,
        location: finding.location,
        name: finding.name,
        project: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        solution: kind_of(String)
      )
    end
  end

  describe '#vulnerability_file_link' do
    let(:project) { create(:project, :repository, :public) }
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let(:finding) { create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high) }
    let(:vulnerability) { create(:vulnerability, findings: [finding], project: project) }

    subject { helper.vulnerability_file_link(vulnerability) }

    it 'returns a link to the vulnerability file location' do
      expect(subject).to include(
        vulnerability.finding.location['file'],
        "#{vulnerability.finding.location['start_line']}",
        vulnerability.finding.pipelines&.last&.sha
      )
    end

    context 'when vulnerability is not linked to a commit' do
      it 'uses the default branch' do
        vulnerability.finding.pipelines = []
        vulnerability.finding.save

        expect(subject).to include(
          vulnerability.project.default_branch
        )
      end
    end

    context 'when vulnerability is not on a specific line' do
      it 'does not include a reference to the line number' do
        vulnerability.finding.location['start_line'] = nil
        vulnerability.finding.save

        expect(subject).not_to include('#L')
      end
    end
  end
end
