# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model do
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
