# frozen_string_literal: true

require 'spec_helper'

describe Packages::Nuget::PackagesMetadataPresenter do
  let_it_be(:packages) { create_list(:nuget_package, 5, name: 'Dummy.Package') }
  let_it_be(:presenter) { described_class.new(packages) }

  describe '#count' do
    subject { presenter.count }

    it {is_expected.to eq 1}
  end

  describe '#items' do
    subject { presenter.items }

    it 'returns an array' do
      items = subject

      expect(items).to be_a Array
      expect(items.size).to eq 1
    end

    it 'returns a summary structure' do
      item = subject.first

      expect(item).to be_a Hash
      %i[json_url lower_version upper_version].each { |field| expect(item[field]).not_to be_blank }
      expect(item[:packages_count]).to eq packages.count
      expect(item[:packages]).to be_a Array
      expect(item[:packages].size).to eq packages.count
    end

    it 'returns the catalog entries' do
      item = subject.first

      item[:packages].each do |pkg|
        expect(pkg).to be_a Hash
        %i[json_url archive_url catalog_entry].each { |field| expect(pkg[field]).not_to be_blank }
        catalog_entry = pkg[:catalog_entry]
        %i[json_url archive_url package_name package_version].each { |field| expect(catalog_entry[field]).not_to be_blank }
        %i[authors summary].each { |field| expect(catalog_entry[field]).to be_blank }
        expect(catalog_entry[:dependencies]).to eq []
      end
    end
  end
end
