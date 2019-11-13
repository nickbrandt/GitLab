# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareContainerScanningReportsService do
  let(:current_user) { project.users.take }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(container_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has container scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_report, project: project) }

      it 'reports new, existing and fixed vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(8)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have container scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'populates fields based on current_user' do
        payload = subject[:data]['added'].first
        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_merge_request_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_dismissal_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('external_id' => 'CVE-2017-15650'))
      end

      it 'reports existing container vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(0)
      end

      it 'reports fixed container scanning vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(8)
        compare_keys = subject[:data]['fixed'].map { |t| t['identifiers'].first['external_id'] }
        expected_keys = %w(CVE-2017-16997 CVE-2017-18269 CVE-2018-1000001 CVE-2016-10228 CVE-2010-4052 CVE-2018-18520 CVE-2018-16869 CVE-2018-18311)
        expect(compare_keys - expected_keys).to eq([])
      end
    end

    context 'when head pipeline has corrupted container scanning vulnerability reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_corrupted_container_scanning_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_corrupted_container_scanning_report, project: project) }

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('JSON parsing failed')
      end

      it 'returns status and error message when pipeline is nil' do
        result = service.execute(nil, head_pipeline)

        expect(result[:status]).to eq(:error)
        expect(result[:status_reason]).to include('JSON parsing failed')
      end
    end
  end
end
