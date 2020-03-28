# frozen_string_literal: true

require 'spec_helper'

describe Packages::Nuget::SearchResultsPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_a) { create(:nuget_package, project: project, name: 'DummyPackageA') }
  let_it_be(:packages_b) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageB') }
  let_it_be(:packages_c) { create_list(:nuget_package, 5, project: project, name: 'DummyPackageC') }
  let_it_be(:search_results) { OpenStruct.new(total_count: 3, results: [package_a, packages_b, packages_c].flatten) }
  let_it_be(:presenter) { described_class.new(search_results) }
  let(:total_count) { presenter.total_count }
  let(:data) { presenter.data }

  describe '#total_count' do
    it 'expects to have 3 total elements' do
      expect(total_count).to eq(3)
    end
  end

  describe '#data' do
    it 'returns the proper data structure' do
      expect(data.size).to eq 3
      pkg_a, pkg_b, pkg_c = data
      expect_package_result(pkg_a, package_a.name, [package_a.version])
      expect_package_result(pkg_b, packages_b.first.name, packages_b.map(&:version))
      expect_package_result(pkg_c, packages_c.first.name, packages_c.map(&:version))
    end

    def expect_package_result(package_json, name, versions)
      expect(package_json[:type]).to eq 'Package'
      expect(package_json[:authors]).to be_blank
      expect(package_json[:name]).to eq(name)
      expect(package_json[:summary]).to be_blank
      expect(package_json[:total_downloads]).to eq 0
      expect(package_json[:verified]).to be
      expect(package_json[:version]).to eq VersionSorter.sort(versions).last # rubocop: disable Style/UnneededSort
      versions.zip(package_json[:versions]).each do |version, version_json|
        expect(version_json[:json_url]).to end_with("#{version}.json")
        expect(version_json[:downloads]).to eq 0
        expect(version_json[:version]).to eq version
      end
    end
  end
end
