# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareDependencyScanningReportsService do
  let(:current_user) { build(:user, :admin) }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { build(:project, :repository) }

  before do
    stub_licensed_features(dependency_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has dependency scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(4)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have dependency scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'populates fields based on current_user' do
        payload = subject[:data]['existing'].first

        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_merge_request_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_dismissal_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(service.current_user).to eq(current_user)
      end

      it 'reports fixed vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('external_id' => 'CVE-2017-5946'))
      end

      it 'reports existing dependency vulenerabilities' do
        expect(subject[:data]['existing'].count).to eq(3)
      end

      it 'reports fixed dependency scanning vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(1)
        compare_keys = subject[:data]['fixed'].map { |t| t['identifiers'].first['external_id'] }
        expected_keys = %w(06565b64-486d-4326-b906-890d9915804d)
        expect(compare_keys - expected_keys).to eq([])
      end
    end

    context 'when head pipeline has corrupted dependency scanning vulnerability reports' do
      let!(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_dependency_scanning_report, project: project) }
      let!(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_dependency_scanning_report, project: project) }

      before do
        error = Gitlab::Ci::Parsers::ParserError.new('Exception: JSON parsing failed')
        allow(base_pipeline).to receive(:license_scanning_report).and_raise(error)
        allow(head_pipeline).to receive(:license_scanning_report).and_raise(error)
      end

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
