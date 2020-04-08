# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Dismiss < ::Mutations::BaseMutation
      graphql_name 'DismissVulnerability'

      authorize :create_requirement

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: 'The ID of the vulnerability to dismiss'

      def resolve(id:)
        vulnerability = authorized_find!(id)

        validate_flag!(vulnerability)

        vulnerability = ::Vulnerabilities::DismissService.new(context[:current_user], vulnerability).execute

        {
          vulnerability: vulnerability.valid? ? vulnerability : nil,
          errors: errors_on_object(vulnerability)
        }
      end

      private

      def validate_flag!(vulnerability)
        return if ::Feature.enabled?(:first_class_vulnerabilities, vulnerability)

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, "first_class_vulnerabilities flag is not enabled on this vulnerability's project"
      end

      def find_object(id)
        GitlabSchema.object_from_id(id)
      end
    end
  end
end
