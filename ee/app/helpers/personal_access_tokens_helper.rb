# frozen_string_literal: true

module PersonalAccessTokensHelper
  def personal_access_token_expiration_policy_licensed?
    License.feature_available?(:personal_access_token_expiration_policy)
  end

  def instance_level_personal_access_token_expiration_policy_enabled?
    Gitlab::CurrentSettings.max_personal_access_token_lifetime && personal_access_token_expiration_policy_licensed?
  end

  def enforce_instance_level_personal_access_token_expiry_policy?
    instance_level_personal_access_token_expiration_policy_enabled? && !current_user.group_managed_account?
  end
end
