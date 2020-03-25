# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class PackagesMetadataItem < Grape::Entity
          expose :json_url, as: :@id
          expose :lower_version, as: :lower
          expose :upper_version, as: :upper
          expose :packages_count, as: :count
          expose :packages, as: :items, using: EE::API::Entities::Nuget::PackageMetadata
        end
      end
    end
  end
end
