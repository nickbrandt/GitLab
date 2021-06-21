# frozen_string_literal: true

module Groups
  module DeployTokens
    class CreateService < Groups::BaseService
      include DeployTokenMethods

      def execute
        deploy_token = create_deploy_token_for(@group, params)

        create_deploy_token_payload_for(deploy_token)
      end
    end
  end
end
