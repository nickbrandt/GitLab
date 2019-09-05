# frozen_string_literal: true

module GitlabSubscriptions
  class CreateLeadService
    def execute(company_params)
      response = subscription_app_client.create_trial_account(company_params)

      if response.success
        { success: true }
      else
        { success: false, errors: response.data&.errors }
      end
    end

    private

    def subscription_app_client
      Gitlab::SubscriptionPortal::Client.new
    end
  end
end
