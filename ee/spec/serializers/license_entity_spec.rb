# frozen_string_literal: true

require 'spec_helper'

describe LicenseEntity do
  describe '#as_json' do
    subject { described_class.represent(license).as_json }

    let(:license) { build(:ci_reports_license_scanning_report, :mit).licenses.first }

    let(:assert_license) do
      {
        name:       'MIT',
        url:        'https://opensource.org/licenses/mit',
        components: [{
                       name:     'rails',
                       blob_path: 'some_path'
                     }]
      }
    end

    before do
      license.dependencies.first.path = 'some_path'
    end

    it { is_expected.to eq(assert_license) }
  end
end
