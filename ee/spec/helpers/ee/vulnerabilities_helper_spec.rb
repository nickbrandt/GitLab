# frozen_string_literal: true

require 'spec_helper'

describe VulnerabilitiesHelper do
  RSpec.shared_examples 'vulnerability properties' do
    it 'has expected vulnerability properties' do
      expect(subject).to include(
        vulnerability_json: vulnerability.to_json,
        project_fingerprint: vulnerability.finding.project_fingerprint,
        create_issue_url: be_present
      )
    end
  end

  before do
    allow(helper).to receive(:can?).and_return(true)
    allow(helper).to receive(:current_user).and_return(user)
  end

  let(:user) { build(:user) }

  describe '#vulnerability_data' do
    let(:vulnerability) { create(:vulnerability, :with_findings) }

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
    let(:vulnerability) { create(:vulnerability, :with_findings) }
    let(:finding) { vulnerability.finding }

    subject { helper.vulnerability_finding_data(finding) }

    it "returns finding information" do
      expect(subject).to include(
        description: finding.description,
        identifiers: finding.identifiers,
        links: finding.links,
        location: finding.location,
        name: finding.name
      )
    end

    context "when finding has a remediations key" do
      let(:finding) { vulnerability.findings.select { |finding| finding.raw_metadata.include?("remediations") }.first }

      it "uses the first remediation summary" do
        expect(subject[:solution]).to start_with "Use GCM mode"
      end
    end

    context "when finding has a solution key" do
      let(:finding) { vulnerability.findings.select { |finding| finding.raw_metadata.include?("solution") }.first }

      it "uses the solution key" do
        expect(subject[:solution]).to start_with "GCM mode"
      end
    end
  end
end
