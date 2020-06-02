# frozen_string_literal: true

module API
  module Helpers
    module TerraformHelpers
      def remote_state_handler
        ::Terraform::RemoteStateHandler.new(user_project, current_user, name: params[:name], lock_id: params[:ID])
      end

      def find_personal_access_token
        find_personal_access_token_from_http_basic_auth
      end

      def find_user_from_job_token
        find_user_from_basic_auth_job
      end
    end
  end
end
