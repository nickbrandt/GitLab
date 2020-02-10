# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to have_one(:conan_file_metadatum) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
  end

  context 'with package filenames' do
    let_it_be(:package_file1) { create(:package_file, :xml, file_name: 'FooBar') }
    let_it_be(:package_file2) { create(:package_file, :xml, file_name: 'ThisIsATest') }

    describe '.with_file_name' do
      let(:filename) { 'FooBar' }

      subject { described_class.with_file_name(filename) }

      it { is_expected.to match_array([package_file1]) }
    end

    describe '.with_file_name_like' do
      let(:filename) { 'foobar' }

      subject { described_class.with_file_name_like(filename) }

      it { is_expected.to match_array([package_file1]) }
    end
  end

  it_behaves_like 'UpdateProjectStatistics' do
    subject { build(:package_file, :jar, size: 42) }
  end
end
