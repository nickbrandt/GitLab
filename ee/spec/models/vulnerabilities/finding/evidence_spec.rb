# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence do
  it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').required }
  it { is_expected.to have_one(:request).class_name('Vulnerabilities::Finding::Evidence::Request').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }
  it { is_expected.to have_one(:response).class_name('Vulnerabilities::Finding::Evidence::Response').with_foreign_key('vulnerability_finding_evidence_id').inverse_of(:evidence) }

  it { is_expected.to validate_length_of(:summary).is_at_most(8_000_000) }

  describe '.new_evidence' do
    let_it_be(:finding) { create(:vulnerabilities_finding) }
    let_it_be(:evidence_hash) { Gitlab::Json.parse(finding.raw_metadata).dig('evidence') }

    subject(:evidence) { Vulnerabilities::Finding::Evidence.evidence_from_hash(finding, evidence_hash) }

    it 'creates a new finding evidence' do
      expect(evidence).not_to be_nil
    end

    it 'creates a response object' do
      expect(evidence.response).not_to be_nil
    end

    it 'creates a request object' do
      expect(evidence.request).not_to be_nil
    end

    it 'populates the created evidence with finding metadata' do
      expect(evidence.summary).to eq(finding.metadata.dig('evidence', 'summary'))
      expect(evidence.request.method).to eq(finding.metadata.dig('evidence', 'request', 'method'))
      expect(evidence.request.url).to eq(finding.metadata.dig('evidence', 'request', 'url'))
      expect(evidence.request.body).to eq(finding.metadata.dig('evidence', 'request', 'body'))
      expect(evidence.request.headers.count).to eq(finding.metadata.dig('evidence', 'request', 'headers').count)
      expect(evidence.request.headers.first.name).to eq(finding.metadata.dig('evidence', 'request', 'headers').first['name'])
      expect(evidence.request.headers.first.value).to eq(finding.metadata.dig('evidence', 'request', 'headers').first['value'])
      expect(evidence.response.reason_phrase).to eq(finding.metadata.dig('evidence', 'response', 'reason_phrase'))
      expect(evidence.response.body).to eq(finding.metadata.dig('evidence', 'response', 'body'))
      expect(evidence.response.headers.count).to eq(finding.metadata.dig('evidence', 'response', 'headers').count)
      expect(evidence.response.headers.first.name).to eq(finding.metadata.dig('evidence', 'response', 'headers').first['name'])
      expect(evidence.response.headers.first.value).to eq(finding.metadata.dig('evidence', 'response', 'headers').first['value'])
    end
  end
end
