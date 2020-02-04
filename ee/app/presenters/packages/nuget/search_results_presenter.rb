# frozen_string_literal: true

module Packages
  module Nuget
    class SearchResultsPresenter
      include API::Helpers::Packages::Nuget::MetadataPresenterHelpers
      include Gitlab::Utils::StrongMemoize

      delegate :total_count, to: :@search

      def initialize(search)
        @search = search
        @package_versions = {}
      end

      def data
        strong_memoize(:data) do
          @search.results.group_by(&:name).map do |package_name, packages|
            {
              type: 'Package',
              authors: '',
              name: package_name,
              version: latest_version(packages),
              versions: build_package_versions(packages),
              summary: '',
              total_downloads: 0,
              verified: true
            }
          end
        end
      end

      private

      def build_package_versions(packages)
        packages.map do |pkg|
          {
            json_url: json_url_for(pkg),
            downloads: 0,
            version: pkg.version
          }
        end
      end

      def latest_version(packages)
        versions = packages.map(&:version).compact
        VersionSorter.sort(versions).last # rubocop: disable Style/UnneededSort
      end
    end
  end
end
