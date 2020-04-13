# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class SearchResults < Grape::Entity
          expose :total_count, as: :totalHits
          expose :data, using: EE::API::Entities::Nuget::SearchResult
        end
      end
    end
  end
end
