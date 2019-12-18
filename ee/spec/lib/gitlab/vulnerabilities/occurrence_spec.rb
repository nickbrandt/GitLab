# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::Occurrence do
  let(:group) { create(:group) }
  let(:project1) { create(:project, :public, namespace: group) }
  let(:project2) { create(:project, :public, namespace: group) }
  let(:critical_vulnerabilities) do
    create_vulnerabilities(2, project2, { severity: :critical, report_type: :sast })
      .sort_by { |x| x.confidence_value }
  end
  let(:med_vulnerabilities) { create_vulnerabilities(1, project1, { severity: :medium, report_type: :sast }) }
  let(:params) { ActionController::Parameters.new }
  let(:user) { create(:user) }
  let(:request) { ActionController::TestRequest.new({ remote_ip: '127.0.0.1' }, ActionController::TestSession.new, nil) }
  let(:response) { ActionDispatch::TestResponse.new }

  before do
    critical_vulnerabilities
    med_vulnerabilities
    group.add_owner(user)
  end

  describe '#findings', :use_clean_rails_memory_store_caching do
    subject(:findings) { described_class.new(group, params, user, request, response).findings }

    context 'feature disabled' do
      before do
        stub_feature_flags(cache_vulnerability_occurrence: false)
      end

      it 'does not call Gitlab::Vulnerabilities::OccurrenceCache' do
        expect(Gitlab::Vulnerabilities::OccurrenceCache).not_to receive(:new)

        findings
      end

      it 'returns the proper format of the findings' do
        expect(findings).to be_an Array
        expect(findings.first).to be_a Hash
      end

      it 'returns the vulnerability occurrences in the correct order' do
        expect(findings.first['id']).to eq critical_vulnerabilities.first.id
        expect(findings.last['id']).to eq med_vulnerabilities.first.id
      end
    end

    context 'feature enabled' do
      before do
        stub_feature_flags(cache_vulnerability_occurrence: true)
      end

      context 'dynamic filters are passed' do
        let(:params) { ActionController::Parameters.new(report_type: :sast) }

        it 'does not call Gitlab::Vulnerabilities::OccurrenceCache' do
          expect(Gitlab::Vulnerabilities::OccurrenceCache).not_to receive(:new)

          findings
        end
      end

      it 'calls Gitlab::Vulnerabilities::OccurrenceCache' do
        expect(Gitlab::Vulnerabilities::OccurrenceCache).to receive(:new).twice.and_call_original

        findings
      end

      it 'returns the proper format for findings' do
        expect(findings).to be_an Array
        expect(findings.first).to be_a Hash
      end

      it 'returns the vulnerability occurrences in the correct order' do
        expect(findings.first['id']).to eq critical_vulnerabilities.first.id
        expect(findings.last['id']).to eq med_vulnerabilities.first.id
      end
    end
  end

  def create_vulnerabilities(count, project, options = {})
    pipeline = create(:ci_pipeline, :success, project: project)

    create_list(
      :vulnerabilities_occurrence,
      count,
      report_type: options[:report_type] || :sast,
      severity:    options[:severity] || :high,
      pipelines:   [pipeline],
      project:     project,
      created_at:  options[:created_at] || Date.today
    )
  end
end
