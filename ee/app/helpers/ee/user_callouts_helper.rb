module EE
  module UserCalloutsHelper
    GOLD_TRIAL = 'gold_trial'.freeze

    def show_gold_trial?(user = current_user)
      !user_dismissed?(GOLD_TRIAL) &&
        (::Gitlab.com? || Rails.env.development?) &&
        !user.any_namespace_with_gold? &&
        !user.any_namespace_with_trial?
    end
  end
end
