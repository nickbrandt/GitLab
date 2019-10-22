# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::ConanFileMetadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }
  end

  describe 'validations' do
    let(:package_file) do
      create(:package_file,
             file: fixture_file_upload('ee/spec/fixtures/conan/recipe_files/conanfile.py'),
             file_name: 'conanfile.py')
    end

    it { is_expected.to validate_presence_of(:package_file) }
    it { is_expected.to validate_presence_of(:recipe_revision) }

    describe '#recipe_revision' do
      it { is_expected.to allow_value("0").for(:recipe_revision) }
      it { is_expected.not_to allow_value(nil).for(:recipe_revision) }
    end

    describe '#package_revision_for_package_file' do
      context 'recipe file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

        it 'is valid with empty value' do
          conan_file_metadatum.package_revision = nil

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with value' do
          conan_file_metadatum.package_revision = '0'

          expect(conan_file_metadatum).to be_invalid
        end
      end

      context 'package file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

        it 'is valid with default value' do
          conan_file_metadatum.package_revision = '0'

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with non-default value' do
          conan_file_metadatum.package_revision = 'foo'

          expect(conan_file_metadatum).to be_invalid
        end
      end
    end

    describe '#conan_package_reference_for_package_file' do
      context 'recipe file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

        it 'is valid with empty value' do
          conan_file_metadatum.conan_package_reference = nil

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with value' do
          conan_file_metadatum.conan_package_reference = '123456789'

          expect(conan_file_metadatum).to be_invalid
        end
      end

      context 'package file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

        it 'is valid with acceptable value' do
          conan_file_metadatum.conan_package_reference = '123456asdf'

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with invalid value' do
          conan_file_metadatum.conan_package_reference = 'foo@bar'

          expect(conan_file_metadatum).to be_invalid
        end

        it 'is invalid when nil' do
          conan_file_metadatum.conan_package_reference = nil

          expect(conan_file_metadatum).to be_invalid
        end
      end
    end
  end
end
