# frozen_string_literal: true

module EE
  module RegistrationsHelper
    def in_paid_signup_flow?
      experiment_enabled?(:paid_signup_flow) && session['user_return_to'] == new_subscriptions_path
    end
  end
end
