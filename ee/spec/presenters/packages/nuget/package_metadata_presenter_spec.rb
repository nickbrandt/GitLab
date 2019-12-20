# frozen_string_literal: true

require 'spec_helper'

describe Packages::Nuget::PackageMetadataPresenter do
  let_it_be(:package) { create(:nuget_package) }
  let_it_be(:presenter) { described_class.new(package) }

  describe '#json_url' do
    let_it_be(:expected_suffix) { "/api/v4/projects/#{package.project_id}/packages/nuget/metadata/#{package.name}/#{package.version}.json" }

    subject { presenter.json_url }

    it { is_expected.to end_with(expected_suffix) }
  end

  describe '#archive_url' do
    let_it_be(:expected_suffix) { "/api/v4/projects/#{package.project_id}/packages/nuget/download/#{package.name}/#{package.version}/#{package.package_files.last.file_name}" }

    subject { presenter.archive_url }

    it { is_expected.to end_with(expected_suffix) }
  end

  describe '#catalog_entry' do
    subject { presenter.catalog_entry }

    it 'returns an entry structure' do
      entry = subject

      expect(entry).to be_a Hash
      %i[json_url archive_url].each { |field| expect(entry[field]).not_to be_blank }
      %i[authors summary].each { |field| expect(entry[field]).to be_blank }
      expect(entry[:dependencies]).to eq []
      expect(entry[:package_name]).to eq package.name
      expect(entry[:package_version]).to eq package.version
    end
  end
end
