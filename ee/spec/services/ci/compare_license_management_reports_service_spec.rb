# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareLicenseManagementReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has license management reports' do
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

    context 'when head pipeline has corrupted license management reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_corrupted_license_management_report, project: project) }

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('JSON parsing failed')
      end
    end
  end
end
