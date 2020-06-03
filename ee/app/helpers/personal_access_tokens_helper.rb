# frozen_string_literal: true

module PersonalAccessTokensHelper
  include Gitlab::Utils::StrongMemoize

  def personal_access_token_expiration_policy_enabled?
    return group_level_personal_access_token_expiration_policy_enabled? if current_user.group_managed_account?

    instance_level_personal_access_token_expiration_policy_enabled?
  end

  def personal_access_token_max_expiry_date
    return group_level_personal_access_token_max_expiry_date if current_user.group_managed_account?

    instance_level_personal_access_token_max_expiry_date
  end

  def personal_access_token_expiration_policy_licensed?
    License.feature_available?(:personal_access_token_expiration_policy)
  end

  def enforce_pat_expiration_feature_available?
    PersonalAccessToken.enforce_pat_expiration_feature_available?
  end

  private

  def instance_level_personal_access_token_expiration_policy_enabled?
    instance_level_personal_access_token_max_expiry_date && personal_access_token_expiration_policy_licensed?
  end

  def instance_level_personal_access_token_max_expiry_date
    ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now
  end

  def group_level_personal_access_token_expiration_policy_enabled?
    group_level_personal_access_token_max_expiry_date && personal_access_token_expiration_policy_licensed?
  end

  def group_level_personal_access_token_max_expiry_date
    current_user.managing_group.max_personal_access_token_lifetime_from_now
  end
end
