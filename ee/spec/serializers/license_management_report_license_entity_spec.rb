# frozen_string_literal: true

require 'spec_helper'

describe LicenseManagementReportLicenseEntity do
  include LicenseManagementReportHelper

  let(:license) { create_license }
  let(:entity) { described_class.new(license) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains the correct dependencies' do
      expect(subject[:dependencies].count).to eq(2)
      expect(subject[:dependencies][0][:name]).to eq('Dependency1')
    end
  end
end
