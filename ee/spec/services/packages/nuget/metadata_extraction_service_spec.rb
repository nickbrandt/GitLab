# frozen_string_literal: true

require 'spec_helper'

describe Packages::Nuget::MetadataExtractionService do
  let(:package_file) { create(:nuget_package).package_files.first }
  let(:service) { described_class.new(package_file.id) }

  describe '#execute' do
    subject { service.execute }

    context 'with valid package file id' do
      expected_metadata = {
        package_name: 'DummyProject.DummyPackage',
        package_version: '1.0.0',
        package_dependencies: [
          {
            name: 'Newtonsoft.Json',
            target_framework: '.NETCoreApp3.0',
            version: '12.0.3'
          }
        ]
      }

      it { is_expected.to eq(expected_metadata) }
    end

    context 'with nuspec file with dependencies' do
      let(:nuspec_filepath) { 'nuget/with_dependencies.nuspec' }

      before do
        allow(service).to receive(:nuspec_file).and_return(fixture_file(nuspec_filepath, dir: 'ee'))
      end

      it { is_expected.to have_key(:package_dependencies) }

      it 'extracts dependencies' do
        dependencies = subject[:package_dependencies]

        expect(dependencies).to include(name: 'Moqi', version: '2.5.6')
        expect(dependencies).to include(name: 'Castle.Core')
        expect(dependencies).to include(name: 'Test.Dependency', version: '2.3.7', target_framework: '.NETStandard2.0')
        expect(dependencies).to include(name: 'Newtonsoft.Json', version: '12.0.3', target_framework: '.NETStandard2.0')
      end
    end

    context 'with invalid package file id' do
      let(:package_file) { OpenStruct.new(id: 555) }

      it { expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError, 'invalid package file') }
    end

    context 'linked to a non nuget package' do
      before do
        package_file.package.maven!
      end

      it { expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError, 'invalid package file') }
    end

    context 'with a 0 byte package file id' do
      before do
        allow_any_instance_of(Packages::PackageFileUploader).to receive(:size).and_return(0)
      end

      it { expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError, 'invalid package file') }
    end

    context 'without the nuspec file' do
      before do
        allow_any_instance_of(Zip::File).to receive(:glob).and_return([])
      end

      it { expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError, 'nuspec file not found') }
    end

    context 'with a too big nuspec file' do
      before do
        allow_any_instance_of(Zip::File).to receive(:glob).and_return([OpenStruct.new(size: 6.megabytes)])
      end

      it { expect { subject }.to raise_error(::Packages::Nuget::MetadataExtractionService::ExtractionError, 'nuspec file too big') }
    end
  end
end
