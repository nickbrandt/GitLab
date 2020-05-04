# frozen_string_literal: true

module Resolvers
  class RequirementsResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
             required: false,
             description: 'IID of the requirement, e.g., "1"'

    argument :iids, [GraphQL::ID_TYPE],
             required: false,
             description: 'List of IIDs of requirements, e.g., [1, 2]'

    argument :sort, Types::SortEnum,
             required: false,
             description: 'List requirements by sort order'

    argument :state, Types::RequirementStateEnum,
             required: false,
             description: 'Filter requirements by state'

    type Types::RequirementType, null: true

    def resolve(**args)
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for issues, so
      # make sure it's loaded and not `nil` before continuing.
      project = object.respond_to?(:sync) ? object.sync : object
      return RequirementsManagement::Requirement.none if project.nil?
      return RequirementsManagement::Requirement.none unless Feature.enabled?(:requirements_management, project, default_enabled: true)

      args[:project_id] = project.id
      args[:iids] ||= [args[:iid]].compact

      RequirementsManagement::RequirementsFinder.new(context[:current_user], args).execute
    end
  end
end
