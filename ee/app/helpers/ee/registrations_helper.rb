# frozen_string_literal: true

module EE
  module RegistrationsHelper
    def in_paid_signup_flow?
      experiment_enabled?(:paid_signup_flow) &&
        (redirect_to = session['user_return_to']) &&
        URI.parse(redirect_to).path == new_subscriptions_path
    end
  end
end
