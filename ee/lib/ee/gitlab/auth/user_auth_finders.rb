# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module UserAuthFinders
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        JOB_TOKEN_HEADER = "HTTP_JOB_TOKEN".freeze
        JOB_TOKEN_PARAM = :job_token

        def find_user_from_bearer_token
          find_current_job&.user ||
            find_user_from_access_token
        end

        def find_user_from_job_token
          return unless job_token

          raise ::Gitlab::Auth::UnauthorizedError unless find_current_job

          find_current_job.user
        end

        override :find_oauth_access_token
        def find_oauth_access_token
          return if scim_request?

          super
        end

        override :validate_access_token!
        def validate_access_token!(scopes: [])
          # if we have a successful job token, don't go ahead and try regular validation as it will fail
          # for the job token
          find_current_job || super
        end

        def scim_request?
          current_request.path.starts_with?("/api/scim/")
        end

        def find_current_job
          return unless job_token

          strong_memoize(:find_current_job) do
            ::Ci::Build.find_by_token(job_token)
          end
        end

        private

        def job_token
          return unless route_authentication_setting[:job_token_allowed]

          strong_memoize(:job_token) do
            (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER] || parsed_oauth_token).to_s
          end
        end
      end
    end
  end
end
