# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module AuthFinders
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        def find_user_from_bearer_token
          find_user_from_job_bearer_token ||
            find_user_from_access_token
        end

        override :find_oauth_access_token
        def find_oauth_access_token
          return if scim_request?

          super
        end

        override :validate_access_token!
        def validate_access_token!(scopes: [])
          # return early if we've already authenticated via a job token
          @current_authenticated_job.present? || super # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def scim_request?
          current_request.path.starts_with?("/api/scim/")
        end

        private

        def find_user_from_job_bearer_token
          return unless route_authentication_setting[:job_token_allowed]

          token = parsed_oauth_token
          return unless token

          job = ::Ci::Build.find_by_token(token)
          return unless job

          @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

          job.user
        end
      end
    end
  end
end
