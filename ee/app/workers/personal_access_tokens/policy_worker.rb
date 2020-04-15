# frozen_string_literal: true

# TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/213791
# Deprecate this worker in GitLab 13.0 in favor of PersonalAccessTokens::Instance::PolicyWorker

module PersonalAccessTokens
  class PolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :personal_access_tokens
    feature_category :authentication_and_authorization

    def perform
      expiration_date = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now

      return unless expiration_date

      User.with_invalid_expires_at_tokens(expiration_date).find_each do |user|
        PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
      end
    end
  end
end
