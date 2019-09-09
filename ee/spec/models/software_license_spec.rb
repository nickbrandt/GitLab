# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicense do
  subject { build(:software_license) }

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe ".create_policy_for!" do
    subject { described_class }
    let(:project) { create(:project) }

    context "when a software license with a given name has already been created" do
      let(:mit_license) { create(:software_license, :mit) }
      let(:result) { subject.create_policy_for!(project: project, name: mit_license.name, approval_status: :approved) }

      specify { expect(result).to be_persisted }
      specify { expect(result).to be_approved }
      specify { expect(result.software_license).to eql(mit_license) }
    end

    context "when a software license with a given name has NOT been created" do
      let(:license_name) { SecureRandom.uuid }
      let(:result) { subject.create_policy_for!(project: project, name: license_name, approval_status: :blacklisted) }

      specify { expect(result).to be_persisted }
      specify { expect(result).to be_blacklisted }
      specify { expect(result.software_license).to be_persisted }
      specify { expect(result.software_license.name).to eql(license_name) }
    end
  end
end
