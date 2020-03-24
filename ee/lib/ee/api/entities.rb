# frozen_string_literal: true

module EE
  module API
    module Entities
      ########################
      # EE-specific entities #
      ########################
      module Nuget
        class ServiceIndex < Grape::Entity
          expose :version
          expose :resources
        end

        class PackageMetadataCatalogEntry < Grape::Entity
          expose :json_url, as: :@id
          expose :authors
          expose :dependencies, as: :dependencyGroups
          expose :package_name, as: :id
          expose :package_version, as: :version
          expose :archive_url, as: :packageContent
          expose :summary
        end

        class PackageMetadata < Grape::Entity
          expose :json_url, as: :@id
          expose :archive_url, as: :packageContent
          expose :catalog_entry, as: :catalogEntry, using: EE::API::Entities::Nuget::PackageMetadataCatalogEntry
        end

        class PackagesMetadataItem < Grape::Entity
          expose :json_url, as: :@id
          expose :lower_version, as: :lower
          expose :upper_version, as: :upper
          expose :packages_count, as: :count
          expose :packages, as: :items, using: EE::API::Entities::Nuget::PackageMetadata
        end

        class PackagesMetadata < Grape::Entity
          expose :count
          expose :items, using: EE::API::Entities::Nuget::PackagesMetadataItem
        end

        class PackagesVersions < Grape::Entity
          expose :versions
        end

        class SearchResultVersion < Grape::Entity
          expose :json_url, as: :@id
          expose :version
          expose :downloads
        end

        class SearchResult < Grape::Entity
          expose :type, as: :@type
          expose :authors
          expose :name, as: :id
          expose :name, as: :title
          expose :summary
          expose :total_downloads, as: :totalDownloads
          expose :verified
          expose :version
          expose :versions, using: EE::API::Entities::Nuget::SearchResultVersion
        end

        class SearchResults < Grape::Entity
          expose :total_count, as: :totalHits
          expose :data, using: EE::API::Entities::Nuget::SearchResult
        end
      end
    end
  end
end
