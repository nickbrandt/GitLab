# frozen_string_literal: true

module PersonalAccessTokensHelper
  include Gitlab::Utils::StrongMemoize

  def personal_access_token_expiration_policy_enabled?
    return false if current_user.group_managed_account?

    instance_level_personal_access_token_expiration_policy_enabled?
  end

  def personal_access_token_max_expiry_date
    instance_level_personal_access_token_max_expiry_date
  end

  def personal_access_token_expiration_policy_licensed?
    License.feature_available?(:personal_access_token_expiration_policy)
  end

  private

  def instance_level_personal_access_token_expiration_policy_enabled?
    instance_level_personal_access_token_max_expiry_date && personal_access_token_expiration_policy_licensed?
  end

  def instance_level_personal_access_token_max_expiry_date
    ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now
  end
end
