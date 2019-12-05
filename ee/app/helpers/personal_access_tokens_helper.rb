# frozen_string_literal: true

module PersonalAccessTokensHelper
  def personal_access_token_expiration_policy_licensed?
    License.feature_available?(:personal_access_token_expiration_policy)
  end

  def personal_access_token_expiration_policy_enabled?
    Gitlab::CurrentSettings.max_personal_access_token_lifetime && personal_access_token_expiration_policy_licensed?
  end
end
