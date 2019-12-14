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

      with_options if: :max_personal_access_token_lifetime_enabled? do
        validates :expires_at, presence: true
        validate :expires_at_before_max_lifetime
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

    def max_expiration_date
      strong_memoize(:max_expiration_date) do
        ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now
      end
    end

    def max_personal_access_token_lifetime_enabled?
      max_expiration_date && License.feature_available?(:personal_access_token_expiration_policy)
    end

    def expires_at_before_max_lifetime
      return if expires_at.blank?

      errors.add(:expires_at, :invalid) if expires_at > max_expiration_date
    end
  end
end
