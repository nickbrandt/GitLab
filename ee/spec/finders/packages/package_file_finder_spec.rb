# frozen_string_literal: true
require 'spec_helper'

describe Packages::PackageFileFinder do
  let(:package) { create(:maven_package) }
  let(:package_file) { package.package_files.first }

  describe '#execute!' do
    it 'returns a package file' do
      finder = described_class.new(package, package_file.file_name)

      expect(finder.execute!).to eq(package_file)
    end

    it 'raises an error' do
      finder = described_class.new(package, 'unknown.jpg')

      expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'with conan_file_type' do
      let(:package) { create(:conan_package) }

      it 'returns a package of the correct file_type' do
        # conan packages contain a conanmanifest.txt file for both conan_file_types
        result = described_class.new(package, 'conanmanifest.txt', conan_file_type: :recipe_file).execute!

        expect(result.conan_file_type).to eq('recipe_file')
        expect(result.conan_file_type).not_to eq('package_file')
      end
    end
  end
end
