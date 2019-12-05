# frozen_string_literal: true

module PersonalAccessTokens
  class PolicyWorker
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
