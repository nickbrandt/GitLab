# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicensePolicy do
  let(:license) { build(:license_scanning_license, :mit) }
  let(:policy) { build(:software_license_policy, software_license: software_license) }
  let(:software_license) { build(:software_license, :mit) }

  describe "#id" do
    context "when a software_policy is provided" do
      it { expect(described_class.new(license, policy).id).to eq(policy.id) }
    end

    context "when a software_policy is NOT provided" do
      it { expect(described_class.new(license, nil).id).to be_nil }
    end
  end

  describe "#name" do
    context "when a software_policy is provided" do
      it { expect(described_class.new(license, policy).name).to eq(policy.software_license.name) }
    end

    context "when a software_policy is NOT provided" do
      it { expect(described_class.new(license, nil).name).to eq(license.name) }
    end
  end

  describe "#url" do
    context "when a license is provided" do
      it { expect(described_class.new(license, policy).url).to eq(license.url) }
    end

    context "when a license is NOT provided" do
      it { expect(described_class.new(nil, policy).id).to be_nil }
    end
  end

  describe "#dependencies" do
    context "when a license is provided" do
      it { expect(described_class.new(license, policy).dependencies).to eq(license.dependencies) }
    end

    context "when a license is NOT provided" do
      it { expect(described_class.new(nil, policy).dependencies).to be_empty }
    end
  end

  describe "#classification" do
    let(:allowed_policy) { build(:software_license_policy, :allowed, software_license: software_license) }
    let(:denied_policy) { build(:software_license_policy, :denied, software_license: software_license) }

    context "when a allowed software_policy is provided" do
      it { expect(described_class.new(license, allowed_policy).classification).to eq("approved") }
    end

    context "when a denied software_policy is provided" do
      it { expect(described_class.new(license, denied_policy).classification).to eq("blacklisted") }
    end

    context "when a software_policy is NOT provided" do
      it { expect(described_class.new(license, nil).classification).to eq("unclassified") }
    end
  end

  describe "#spdx_identifier" do
    context "when a software_policy is provided" do
      it { expect(described_class.new(license, policy).spdx_identifier).to eq(policy.software_license.spdx_identifier) }
    end

    context "when a software_policy is provided but does not have a SPDX Id" do
      let(:software_license) { build(:software_license, spdx_identifier: nil) }

      it { expect(described_class.new(license, policy).spdx_identifier).to eq(license.id) }
    end

    context "when a software_policy is NOT provided" do
      it { expect(described_class.new(license, nil).spdx_identifier).to eq(license.id) }
    end
  end
end
