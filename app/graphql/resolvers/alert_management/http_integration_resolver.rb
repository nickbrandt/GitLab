# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class HttpIntegrationResolver < BaseResolver
      alias_method :project, :synchronized_object

      type Types::AlertManagement::HttpIntegrationType, null: true

      argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
               required: true,
               description: 'ID of the integration.'

      def resolve(**args)
        return unless Ability.allowed?(current_user, :admin_operations, project)

        GitlabSchema.object_from_id(args[:id], expected_class: ::AlertManagement::HttpIntegration)
      end
    end
  end
end
