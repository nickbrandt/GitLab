# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class PackageMetadataCatalogEntry < Grape::Entity
          expose :json_url, as: :@id
          expose :authors
          expose :dependencies, as: :dependencyGroups
          expose :package_name, as: :id
          expose :package_version, as: :version
          expose :tags
          expose :archive_url, as: :packageContent
          expose :summary
          expose :metadatum, using: EE::API::Entities::Nuget::Metadatum, merge: true
        end
      end
    end
  end
end
