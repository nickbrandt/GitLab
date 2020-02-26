# frozen_string_literal: true

module EE
  # PersonalAccessToken EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `PersonalAccessToken` model
  module PersonalAccessToken
    extend ActiveSupport::Concern

    prepended do
      include ::Gitlab::Utils::StrongMemoize
      include FromUnion

      scope :with_no_expires_at, -> { where(revoked: false, expires_at: nil) }
      scope :with_expires_at_after, ->(max_lifetime) { where(revoked: false).where('expires_at > ?', max_lifetime) }

      with_options if: :enforce_instance_level_personal_access_token_expiry_policy? do
        validates :expires_at, presence: true
        validate :expires_at_before_instance_level_expiry_date
      end
    end

    class_methods do
      def pluck_names
        pluck(:name)
      end

      def with_invalid_expires_at(max_lifetime, limit = 1_000)
        from_union(
          [
            with_no_expires_at.limit(limit),
            with_expires_at_after(max_lifetime).limit(limit)
          ]
        )
      end
    end

    private

    def enforce_instance_level_personal_access_token_expiry_policy?
      instance_level_personal_access_token_expiry_policy_enabled? && !user.group_managed_account?
    end

    def instance_level_expiry_date
      strong_memoize(:instance_level_expiry_date) do
        ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now
      end
    end

    def instance_level_personal_access_token_expiry_policy_enabled?
      instance_level_expiry_date && License.feature_available?(:personal_access_token_expiration_policy)
    end

    def expires_at_before_instance_level_expiry_date
      return if expires_at.blank?

      errors.add(:expires_at, :invalid) if expires_at > instance_level_expiry_date
    end
  end
end
