# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareLicenseScanningReportsService do
  let(:current_user) { project.users.take }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(license_management: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has license scanning reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_management_report, project: project) }

      it 'reports new licenses' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['new_licenses'].count).to eq(4)
        expect(subject[:data]['new_licenses']).to include(a_hash_including('name' => 'MIT'))
      end
    end

    context 'when base and head pipelines have test reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_license_management_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_management_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'reports new licenses' do
        expect(subject[:data]['new_licenses'].count).to eq(1)
        expect(subject[:data]['new_licenses']).to include(a_hash_including('name' => 'WTFPL'))
      end

      it 'reports existing licenses' do
        expect(subject[:data]['existing_licenses'].count).to eq(1)
        expect(subject[:data]['existing_licenses']).to include(a_hash_including('name' => 'MIT'))
      end

      it 'reports removed licenses' do
        expect(subject[:data]['removed_licenses'].count).to eq(3)
        expect(subject[:data]['removed_licenses']).to include(a_hash_including('name' => 'New BSD'))
      end
    end

    context 'when head pipeline has corrupted license scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_corrupted_license_management_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_corrupted_license_management_report, project: project) }

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
