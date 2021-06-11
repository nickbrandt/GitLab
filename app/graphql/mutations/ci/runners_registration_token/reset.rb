# frozen_string_literal: true

module Mutations
  module Ci
    module RunnersRegistrationToken
      class Reset < BaseMutation
        graphql_name 'RunnersRegistrationTokenReset'

        authorize :update_runners_registration_token

        ScopeID = ::GraphQL::ID_TYPE

        argument :id, ScopeID,
          required: true,
          description: 'ID of the project or group to reset the token for. Omit if resetting instance runner token.'

        field :token,
          GraphQL::STRING_TYPE,
          null: true,
          description: 'The runner token after mutation.'

        def resolve(**args)
          {
            token: reset_token(args[:id]),
            errors: []
          }
        end

        private

        def find_object(id:)
          return unless id

          GitlabSchema.object_from_id(id, expected_type: [::Project, ::Group])
        end

        def reset_token(id)
          if id.blank?
            authorize!(:global)

            ApplicationSetting.current.reset_runners_registration_token!
            ApplicationSetting.current_without_cache.runners_registration_token
          else
            project_or_group = authorized_find!(id: id)
            project_or_group.reset_runners_token!
            project_or_group.runners_token
          end
        end
      end
    end
  end
end
