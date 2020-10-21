# frozen_string_literal: true

module Mutations
  module Admin
    module Analytics
      module DevopsAdoption
        module Segments
          class Update < BaseMutation
            include Mixins::RequireAdminPermission
            include Mixins::Common

            graphql_name 'UpdateDevopsAdoptionSegment'

            argument :id, ::Types::GlobalIDType[::Analytics::DevopsAdoption::Segment],
              required: true,
              description: "ID of the segment"

            def resolve(id:, name:, group_ids: nil, **)
              segment = id.find
              params = build_params({ name: name, group_ids: group_ids }, segment.segment_selections)

              segment.update(params)
              resolve_segment(segment)
            end
          end
        end
      end
    end
  end
end
