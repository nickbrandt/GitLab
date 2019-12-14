# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::ConanMetadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:package_username) }
    it { is_expected.to validate_presence_of(:package_channel) }

    describe '#package_username' do
      it { is_expected.to allow_value("my-package+username").for(:package_username) }
      it { is_expected.not_to allow_value("my/package").for(:package_username) }
      it { is_expected.not_to allow_value("my(package)").for(:package_username) }
      it { is_expected.not_to allow_value("my@package").for(:package_username) }
    end

    describe '#package_channel' do
      it { is_expected.to allow_value("beta").for(:package_channel) }
      it { is_expected.to allow_value("stable+1.0").for(:package_channel) }
      it { is_expected.not_to allow_value("my/channel").for(:package_channel) }
      it { is_expected.not_to allow_value("my(channel)").for(:package_channel) }
      it { is_expected.not_to allow_value("my@channel").for(:package_channel) }
    end
  end

  describe '#recipe' do
    let(:package) { create(:conan_package) }

    it 'returns the recipe' do
      expect(package.conan_recipe).to eq("#{package.name}/#{package.version}@#{package.conan_metadatum.package_username}/#{package.conan_metadatum.package_channel}")
    end
  end

  describe '#recipe_url' do
    let(:package) { create(:conan_package) }

    it 'returns the recipe url' do
      expect(package.conan_recipe_path).to eq("#{package.name}/#{package.version}/#{package.conan_metadatum.package_username}/#{package.conan_metadatum.package_channel}")
    end
  end

  describe '.package_username_from' do
    let(:full_path) { 'foo/bar/baz-buz' }

    it 'returns the username formatted package path' do
      expect(described_class.package_username_from(full_path: full_path)).to eq('foo+bar+baz-buz')
    end
  end

  describe '.full_path_from' do
    let(:username) { 'foo+bar+baz-buz' }

    it 'returns the username formatted package path' do
      expect(described_class.full_path_from(package_username: username)).to eq('foo/bar/baz-buz')
    end
  end
end
