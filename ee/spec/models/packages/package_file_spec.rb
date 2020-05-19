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
    let_it_be(:metadatum) { create(:conan_file_metadatum, :package_file) }
    let_it_be(:reference) { metadatum.conan_package_reference}

    it 'returns matching packages' do
      expect(described_class.with_conan_package_reference(reference))
        .to eq([metadatum.package_file])
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

  describe '#calculate_checksum!' do
    let(:package_file) { create(:conan_package_file, :conan_recipe_file) }

    it 'sets `verification_checksum` to SHA256 sum of the file' do
      expected = Digest::SHA256.file(package_file.file.path).hexdigest

      expect { package_file.calculate_checksum! }
        .to change { package_file.verification_checksum }.from(nil).to(expected)
    end

    it 'sets `checksum` to nil for a non-existent file' do
      checksum = Digest::SHA256.file(package_file.file.path).hexdigest
      package_file.verification_checksum = checksum

      allow(package_file).to receive(:file_exist?).and_return(false)

      expect { package_file.calculate_checksum! }
        .to change { package_file.verification_checksum }.from(checksum).to(nil)
    end
  end

  context 'new file' do
    it 'calls checksum worker' do
      allow(Geo::BlobVerificationPrimaryWorker).to receive(:perform_async)

      package_file = create(:conan_package_file, :conan_recipe_file)

      expect(Geo::BlobVerificationPrimaryWorker).to have_received(:perform_async).with('package_file', package_file.id)
    end
  end
end
