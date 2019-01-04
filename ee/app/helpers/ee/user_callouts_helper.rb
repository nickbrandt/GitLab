# frozen_string_literal: true

module EE
  module UserCalloutsHelper
    GOLD_TRIAL = 'gold_trial'.freeze

    def show_gold_trial?(user = current_user)
      return false unless user
      return false if user_dismissed?(GOLD_TRIAL)
      return false unless show_gold_trial_suitable_env?

      users_namespaces_clean?(user)
    end

    def show_gold_trial_suitable_env?
      (::Gitlab.com? || Rails.env.development?) &&
        !::Gitlab::Database.read_only?
    end

    def users_namespaces_clean?(user)
      return false if user.any_namespace_with_gold?

      !user.any_namespace_with_trial?
    end
  end
end
