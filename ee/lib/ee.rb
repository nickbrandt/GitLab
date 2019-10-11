# frozen_string_literal: true

module EE
  SUBSCRIPTIONS_URL = ENV.fetch('CUSTOMER_PORTAL_URL', 'https://customers.gitlab.com').freeze
  SUBSCRIPTIONS_PLANS_URL = "#{SUBSCRIPTIONS_URL}/plans".freeze
  SUBSCRIPTIONS_MORE_MINUTES_URL = "#{SUBSCRIPTIONS_URL}/buy_pipeline_minutes".freeze
  CUSTOMER_SUPPORT_URL = 'https://support.gitlab.com'.freeze
end
