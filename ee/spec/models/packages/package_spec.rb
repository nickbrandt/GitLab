# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Packages::Package, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:package_files) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe '#name' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:name) }
      it { is_expected.to allow_value("my.app-11.07.2018").for(:name) }
      it { is_expected.not_to allow_value("my(dom$$$ain)com.my-app").for(:name) }
    end
  end

  describe '.by_name_and_file_name' do
    let!(:package) { create(:npm_package) }
    let!(:package_file) { package.package_files.first }

    subject { described_class }

    it 'finds a package with correct arguiments' do
      expect(subject.by_name_and_file_name(package.name, package_file.file_name)).to eq(package)
    end

    it 'will raise error if not found' do
      expect { subject.by_name_and_file_name('foo', 'foo-5.5.5.tgz') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.last_of_each_version' do
    let!(:package1) { create(:npm_package, version: '1.0.0') }
    let!(:package2) { create(:npm_package, version: '1.0.1') }
    let!(:package3) { create(:npm_package, version: '1.0.1') }

    subject { described_class.last_of_each_version }

    it 'includes only latest package per version' do
      is_expected.to include(package1, package3)
      is_expected.not_to include(package2)
    end
  end

  describe '.has_version' do
    let!(:package1) { create(:npm_package, version: '1.0.0') }
    let!(:package2) { create(:npm_package, version: nil) }
    let!(:package3) { create(:npm_package, version: '1.0.1') }

    subject { described_class.has_version }

    it 'includes only packages with version attribute' do
      is_expected.to match_array([package1, package3])
    end
  end
end
