# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::LicenseManagement::ReportsComparer do
  let(:report_1) { build :ci_reports_license_management_report, :report_1 }
  let(:report_2) { build :ci_reports_license_management_report, :report_2 }
  let(:report_comparer) { described_class.new(report_1, report_2) }

  describe '#new_licenses' do
    subject { report_comparer.new_licenses }

    it 'reports new licenses' do
      expect(subject.count).to eq 1
      expect(subject[0].name).to eq 'Apache 2.0'
    end
  end

  describe '#existing_licenses' do
    subject { report_comparer.existing_licenses }

    it 'reports existing licenses' do
      expect(subject.count).to eq 1
      expect(subject[0].name).to eq 'MIT'
    end
  end

  describe '#removed_licenses' do
    subject { report_comparer.removed_licenses }

    it 'reports removed licenses' do
      expect(subject.count).to eq 1
      expect(subject[0].name).to eq 'WTFPL'
    end
  end
end
