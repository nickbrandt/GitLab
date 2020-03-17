# frozen_string_literal: true

module PersonalAccessTokens
  class PolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :personal_access_tokens
    feature_category :authentication_and_authorization

    def perform
      expiration_date = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now

      return unless expiration_date

      # for users who are not managed by any group
      User.not_managed.with_invalid_expires_at_tokens(expiration_date).find_each do |user|
        PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
      end

      # for users who are managed by groups, but follow the instance level policy

      # rubocop: disable CodeReuse/ActiveRecord
      managed_groups_following_instance_policy =
        Group.joins(:saml_provider).where(max_personal_access_token_lifetime: nil, saml_providers: { enabled: true, enforced_sso: true, enforced_group_managed_accounts: true })

      managed_groups_following_instance_policy.find_each do |group|
        next unless group.feature_available?(:group_saml) && ::Feature.enabled?(:enforced_sso, group) && ::Feature.enabled?(:group_managed_accounts, group)

        User.managed_by(group).with_invalid_expires_at_tokens(expiration_date).find_each do |user|
          PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
