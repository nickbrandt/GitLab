# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::LicenseManagement::LicenseManagement do
  describe '#parse!' do
    subject { described_class.new.parse!(data, report) }

    let(:report) { Gitlab::Ci::Reports::LicenseManagement::Report.new }

    context 'when data is a JSON license management report' do
      let(:data) { File.read(Rails.root.join('spec/fixtures/security-reports/master/gl-license-management-report.json')) }

      it 'parses without error' do
        expect { subject }.not_to raise_error

        expect(report.licenses.count).to eq(4)
      end
    end
  end
end
