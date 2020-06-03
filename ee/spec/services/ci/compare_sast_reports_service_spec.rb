# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareSastReportsService do
  let(:current_user) { build(:user, :admin) }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { build(:project, :repository) }

  before do
    stub_licensed_features(container_scanning: true)
    stub_licensed_features(sast: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has sast reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(33)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have sast reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_feature_branch, project: project) }

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

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('name' => 'CWE-120'))
      end

      it 'reports existing sast vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(29)
      end

      it 'reports fixed sast vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(4)
        compare_keys = subject[:data]['fixed'].map { |t| t['identifiers'].first['external_id'] }
        expected_keys = %w(char fopen strcpy char)
        expect(compare_keys - expected_keys).to eq([])
      end
    end
  end
end
