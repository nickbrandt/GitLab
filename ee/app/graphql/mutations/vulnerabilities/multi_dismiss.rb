# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class MultiDismiss < BaseMutation
      graphql_name 'DismissVulnerabilities'

      authorize :admin_vulnerability

      field :vulnerabilities, [Types::VulnerabilityType],
            null: true,
            description: 'Vulnerabilities after dismissal'

      argument :vulnerability_ids,
               GraphQL::ID_TYPE,
               required: true,
               description: 'IDs of the vulnerabilities to be dismissed'

      argument :comment,
               GraphQL::STRING_TYPE,
               required: false,
               description: 'Reason why vulnerabilities should be dismissed'

      def resolve(vulnerability_ids:, comment: nil)
        vulnerability_ids
          .map(&method(:authorized_find!))
          .map { |vulnerability| dismiss_vulnerability(vulnerability, comment) }
          .then do |vulnerabilities|
            {
              vulnerabilities: vulnerabilities,
              errors: vulnerabilities.flat_map { |vulnerability| vulnerability.errors.full_messages || [] }
            }
          end
      end

      private

      def dismiss_vulnerability(vulnerability, comment)
        ::Vulnerabilities::DismissService.new(current_user, vulnerability, comment).execute
      end

      def find_object(id)
        GitlabSchema.object_from_id(id)
      end
    end
  end
end
