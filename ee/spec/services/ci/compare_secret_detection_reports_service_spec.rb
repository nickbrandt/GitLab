# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareSecretDetectionReportsService do
  let(:current_user) { build(:user, :admin) }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { build(:project, :repository) }

  before do
    stub_licensed_features(container_scanning: true)
    stub_licensed_features(secret_detection: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has secret_detection reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have secret_detection reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'populates fields based on current_user' do
        payload = subject[:data]['existing'].first
        expect(payload).to be_nil
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(0)
      end

      it 'reports existing secret_detection vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(0)
      end

      it 'reports fixed secret_detection vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(1)
        compare_keys = subject[:data]['fixed'].map { |t| t['identifiers'].first['external_id'] }
        expected_keys = %w(AWS)
        expect(compare_keys - expected_keys).to eq([])
      end
    end
  end
end
