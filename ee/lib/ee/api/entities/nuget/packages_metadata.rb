# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class PackagesMetadata < Grape::Entity
          expose :count
          expose :items, using: EE::API::Entities::Nuget::PackagesMetadataItem
        end
      end
    end
  end
end
