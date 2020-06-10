# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VulnerabilitiesHelper do
  let_it_be(:user) { build(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:finding) { create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high) }
  let_it_be(:vulnerability) { create(:vulnerability, title: "My vulnerability", project: project, findings: [finding]) }
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
  let(:finding_serializer_hash) do
    finding.slice(:description,
      :identifiers,
      :links,
      :location,
      :name,
      :issue_feedback,
      :project,
      :remediations,
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

      finding_serializer_stub = instance_double("Vulnerabilities::FindingSerializer")
      expect(Vulnerabilities::FindingSerializer).to receive(:new).and_return(finding_serializer_stub)
      expect(finding_serializer_stub).to receive(:represent).with(finding).and_return(finding_serializer_hash)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    it 'has expected vulnerability properties' do
      expect(subject).to include(
        vulnerability_json: kind_of(String),
        project_fingerprint: vulnerability.finding.project_fingerprint,
        create_issue_url: "/#{project.full_path}/-/vulnerability_feedback",
        notes_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/notes",
        discussions_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/discussions",
        has_mr: anything,
        vulnerability_feedback_help_path: kind_of(String),
        finding_json: kind_of(String),
        create_mr_url: "/#{project.full_path}/-/vulnerability_feedback",
        timestamp: Time.now.to_i
      )
    end
  end

  describe '#vulnerability_data' do
    subject { helper.vulnerability_data(vulnerability, pipeline) }

    describe 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:pipelineData) { Gitlab::Json.parse(subject[:pipeline_json]) }

      include_examples 'vulnerability properties'

      it 'returns expected pipeline data' do
        expect(pipelineData).to include(
          'id' => pipeline.id,
          'created_at' => pipeline.created_at.iso8601,
          'url' => be_present,
          'source_branch' => pipeline.ref
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
    subject { helper.vulnerability_finding_data(vulnerability) }

    it 'returns finding information' do
      expect(subject).to match(
        description: finding.description,
        identifiers: kind_of(Array),
        issue_feedback: anything,
        merge_request_feedback: anything,
        links: finding.links,
        location: finding.location,
        name: finding.name,
        project: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        remediations: finding.remediations,
        solution: kind_of(String)
      )

      expect(subject[:location]['blob_path']).to match(kind_of(String))
    end

    context 'when there is no file' do
      before do
        vulnerability.finding.location['file'] = nil
        vulnerability.finding.location.delete('blob_path')
      end

      it 'does not have a blob_path if there is no file' do
        expect(subject[:location]).not_to have_key('blob_path')
      end
    end
  end
end
