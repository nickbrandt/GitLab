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
        expect(subject[:data]['new_licenses'].count).to be(4)
        expect(subject[:data]['new_licenses'].any? { |license| license['name'] == 'MIT' } ).to be_truthy
      end
    end

    context 'when base and head pipelines have test reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_license_management_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_management_report_2, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'reports new licenses' do
        expect(subject[:data]['new_licenses'].count).to be(1)
        expect(subject[:data]['new_licenses'][0]['name']).to eq('WTFPL')
      end

      it 'reports existing licenses' do
        expect(subject[:data]['existing_licenses'].count).to be(1)
        expect(subject[:data]['existing_licenses'][0]['name']).to eq('MIT')
      end

      it 'reports removed licenses' do
        expect(subject[:data]['removed_licenses'].count).to be(3)
        expect(subject[:data]['removed_licenses'].any? { |license| license['name'] == 'New BSD' } ).to be_truthy
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
