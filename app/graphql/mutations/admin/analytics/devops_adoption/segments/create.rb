# frozen_string_literal: true

module Mutations
  module Admin
    module Analytics
      module DevopsAdoption
        module Segments
          class Create < BaseMutation
            include Mixins::RequireAdminPermission
            include Mixins::Common

            graphql_name 'CreateDevopsAdoptionSegment'

            def resolve(name:, group_ids: [], **)
              params = build_params(name: name, group_ids: group_ids)
              resolve_segment(::Analytics::DevopsAdoption::Segment.create(params))
            end
          end
        end
      end
    end
  end
end
