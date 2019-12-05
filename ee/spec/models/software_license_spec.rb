# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicense do
  subject { build(:software_license) }

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:spdx_identifier).is_at_most(255) }
  end

  describe '.create_policy_for!' do
    subject { described_class }

    let(:project) { create(:project) }

    context 'when a software license with a given name has already been created' do
      let(:mit_license) { create(:software_license, :mit) }
      let(:result) { subject.create_policy_for!(project: project, name: mit_license.name, classification: :approved) }

      specify { expect(result).to be_persisted }
      specify { expect(result).to be_approved }
      specify { expect(result.software_license).to eql(mit_license) }
    end

    context 'when a software license with a given name has NOT been created' do
      let(:license_name) { SecureRandom.uuid }
      let(:result) { subject.create_policy_for!(project: project, name: license_name, classification: :blacklisted) }

      specify { expect(result).to be_persisted }
      specify { expect(result).to be_blacklisted }
      specify { expect(result.software_license).to be_persisted }
      specify { expect(result.software_license.name).to eql(license_name) }
    end
  end

  describe 'scopes' do
    subject { described_class }

    let_it_be(:mit) { create(:software_license, :mit, spdx_identifier: 'MIT') }
    let_it_be(:apache_2) { create(:software_license, :apache_2_0, spdx_identifier: nil) }

    describe '.by_spdx' do
      it { expect(subject.by_spdx(mit.spdx_identifier)).to contain_exactly(mit) }
    end

    describe '.spdx' do
      it { expect(subject.spdx).to contain_exactly(mit) }
    end

    describe '.by_spdx' do
      it { expect(subject.by_spdx(mit.spdx_identifier)).to contain_exactly(mit) }
    end

    describe '.spdx' do
      it { expect(subject.spdx).to contain_exactly(mit) }
    end

    describe '.by_name' do
      it { expect(subject.by_name(mit.name)).to contain_exactly(mit) }
    end

    describe '.unknown' do
      it { expect(subject.unknown).to contain_exactly(apache_2) }
    end

    describe '.grouped_by_name' do
      it { expect(subject.grouped_by_name.count).to eql(mit.name => 1, apache_2.name => 1) }
    end

    describe '.ordered' do
      it { expect(subject.ordered.pluck(:name)).to eql([apache_2.name, mit.name]) }
    end
  end

  describe "#canonical_id" do
    context "when an SPDX identifier is available" do
      it { expect(build(:software_license, spdx_identifier: 'MIT').canonical_id).to eq('MIT') }
    end

    context "when an SPDX identifier is not available" do
      it { expect(build(:software_license, name: 'MIT License', spdx_identifier: nil).canonical_id).to eq('mit license') }
    end
  end
end
