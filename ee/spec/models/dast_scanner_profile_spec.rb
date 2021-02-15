# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastScannerProfile, type: :model do
  subject { create(:dast_scanner_profile) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe 'scopes' do
    describe '.project_id_in' do
      it 'returns the dast_scanner_profiles for given projects' do
        result = DastScannerProfile.project_id_in([subject.project.id])
        expect(result).to eq([subject])
      end
    end

    describe '.with_name' do
      it 'returns the dast_scanner_profiles with given name' do
        result = DastScannerProfile.with_name(subject.name)
        expect(result).to eq([subject])
      end
    end
  end

  describe 'full_scan_enabled?' do
    describe 'when is active scan' do
      subject { create(:dast_scanner_profile, scan_type: :active).full_scan_enabled? }

      it { is_expected.to eq(true) }
    end

    describe 'when is passive scan' do
      subject { create(:dast_scanner_profile, scan_type: :passive).full_scan_enabled? }

      it { is_expected.to eq(false) }
    end
  end
end
