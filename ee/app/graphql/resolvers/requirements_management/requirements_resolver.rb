# frozen_string_literal: true

module Resolvers
  module RequirementsManagement
    class RequirementsResolver < BaseResolver
      include LooksAhead
      include CommonRequirementArguments

      type ::Types::RequirementsManagement::RequirementType.connection_type, null: true

      argument :iid, GraphQL::ID_TYPE,
               required: false,
               description: 'IID of the requirement, e.g., "REQ-1".',
               prepare: ->(iid, ctx) {
                 return iid unless iid
                 return iid if iid.to_s.match?(/^\d+$/)

                 raise Gitlab::Graphql::Errors::ArgumentError, "Requirement IIDs are either numeric or start with 'REQ-', for example REQ-1" unless ::RequirementsManagement::Requirement.matches_requirement_iid?(iid)

                 ::RequirementsManagement::Requirement.requirement_iid_to_numeric_iid(iid.dup)
               }

      argument :iids, [GraphQL::ID_TYPE],
               required: false,
               description: 'List of IIDs of requirements, e.g., ["REQ-1", "REQ-2"].', prepare: ->(iids, ctx) {
                 iids.map { |iid| ::RequirementsManagement::Requirement.requirement_iid_to_numeric_iid(iid.dup) }
               }

      argument :last_test_report_state, ::Types::RequirementsManagement::RequirementStatusFilterEnum,
               required: false,
               description: 'The state of latest requirement test report.'

      def resolve_with_lookahead(**args)
        # The project could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the project to query for issues, so
        # make sure it's loaded and not `nil` before continuing.
        project = object.respond_to?(:sync) ? object.sync : object
        return ::RequirementsManagement::Requirement.none if project.nil?

        args[:project_id] = project.id
        args[:iids] ||= Array.wrap(args[:iid])

        apply_lookahead(find_requirements(args))
      end

      private

      def preloads
        {
          last_test_report_manually_created: [:test_reports],
          last_test_report_state: [:test_reports, { test_reports: [:build] }]
        }
      end

      def find_requirements(args)
        ::RequirementsManagement::RequirementsFinder.new(context[:current_user], args).execute
      end
    end
  end
end
