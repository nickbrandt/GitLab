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

    before do
      allow_any_instance_of(Packages::PackageFileUploader).to receive(:size).and_return(42)
    end
  end

  describe '.with_conan_package_reference' do
    let_it_be(:non_matching_package_file) { create(:package_file, :nuget) }
    let_it_be(:package_file) { create(:conan_package_file, :conan_package) }
    let_it_be(:reference) { package_file.conan_file_metadatum.conan_package_reference}

    it 'returns matching packages' do
      expect(described_class.with_conan_package_reference(reference))
        .to eq([package_file])
    end
  end

  describe '#update_file_metadata callback' do
    let(:package_file) { build(:package_file, :nuget, file_store: 0, size: nil) }

    subject { package_file.save! }

    it 'updates metadata columns' do
      expect(package_file)
        .to receive(:update_file_metadata)
        .and_call_original

      subject

      expect(package_file.file_store).to eq 1
      expect(package_file.size).to eq 3513
    end
  end
end
