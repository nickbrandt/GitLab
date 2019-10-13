# frozen_string_literal: true

require 'spec_helper'

describe Security::LicensesListService do
  describe '#execute' do
    let!(:pipeline) { create(:ee_ci_pipeline, :with_license_management_report) }

    subject { described_class.new(pipeline: pipeline).execute }

    before do
      stub_licensed_features(license_management: true)
    end

    it 'returns array of Licenses' do
      is_expected.to be_an(Array)
    end
  end
end
