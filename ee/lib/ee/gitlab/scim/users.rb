# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class Users < Grape::Entity
        expose :schemas
        expose :total_results, as: :totalResults
        expose :items_per_page, as: :itemsPerPage
        expose :start_index, as: :startIndex

        present_collection true, :Resources
        expose :resources, as: :Resources, using: ::EE::Gitlab::Scim::User

        private

        DEFAULT_SCHEMA = 'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ITEMS_PER_PAGE = 20
        START_INDEX = 1

        def schemas
          [DEFAULT_SCHEMA]
        end

        def total_results
          1
        end

        def items_per_page
          ITEMS_PER_PAGE
        end

        def start_index
          START_INDEX
        end

        # We only support a single resource at the moment
        # Please update `total_results` to `resources.count` once this changes
        def resources
          [object]
        end
      end
    end
  end
end
