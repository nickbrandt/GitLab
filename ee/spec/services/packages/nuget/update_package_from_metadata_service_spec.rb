# frozen_string_literal: true

require 'spec_helper'

describe Packages::Nuget::UpdatePackageFromMetadataService do
  let(:package) { create(:nuget_package) }
  let(:package_file) { package.package_files.first }
  let(:service) { described_class.new(package_file) }
  let(:package_name) { 'DummyProject.DummyPackage' }
  let(:package_version) { '1.0.0' }
  let(:package_file_name) { 'dummyproject.dummypackage.1.0.0.nupkg' }

  describe '#execute' do
    subject { service.execute }

    before do
      stub_package_file_object_storage(enabled: true, direct_upload: true)
    end

    it 'updates package and package file' do
      subject

      expect(package.reload.name).to eq(package_name)
      expect(package.version).to eq(package_version)
      expect(package_file.reload.file_name).to eq(package_file_name)
      # hard reset needed to properly reload package_file.file
      expect(Packages::PackageFile.find(package_file.id).file.size).not_to eq 0
    end

    context 'with exisiting package' do
      let!(:existing_package) { create(:nuget_package, project: package.project, name: package_name, version: package_version) }

      it 'link existing package and updates package file' do
        expect { subject }.to change { ::Packages::Package.count }.by(-1)
        expect(package_file.reload.file_name).to eq(package_file_name)
        expect(package_file.package).to eq(existing_package)
      end
    end

    context 'with package file not containing a nuspec file' do
      before do
        allow_any_instance_of(Zip::File).to receive(:glob).and_return([])
      end

      it 'raises an error' do
        expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError)
      end
    end

    context 'with package file with a blank package name' do
      before do
        allow(service).to receive(:package_name).and_return('')
      end

      it 'raises an error' do
        expect { subject }.to raise_error(::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError)
      end
    end

    context 'with package file with a blank package version' do
      before do
        allow(service).to receive(:package_version).and_return('')
      end

      it 'raises an error' do
        expect { subject }.to raise_error(::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError)
      end
    end

    context 'with an invalid package version' do
      invalid_versions = [
        '555',
        '1.2',
        '1./2.3',
        '../../../../../1.2.3',
        '%2e%2e%2f1.2.3'
      ]

      invalid_versions.each do |invalid_version|
        it "raises an error for version #{invalid_version}" do
          allow(service).to receive(:package_version).and_return(invalid_version)

          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Version is invalid')
          expect(package_file.file_name).not_to include(invalid_version)
          expect(package_file.file.file.path).not_to include(invalid_version)
        end
      end
    end
  end
end
