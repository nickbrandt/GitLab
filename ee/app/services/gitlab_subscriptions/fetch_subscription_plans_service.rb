# frozen_string_literal: true
module GitlabSubscriptions
  class FetchSubscriptionPlansService
    include Gitlab::Utils::StrongMemoize

    URL = "#{EE::SUBSCRIPTIONS_URL}/gitlab_plans".freeze

    def initialize(plan:, namespace_id: nil)
      @plan = plan
      @namespace_id = namespace_id
    end

    def execute
      cached { send_request }
    end

    private

    def send_request
      response = Gitlab::HTTP.get(
        URL,
        allow_local_requests: true,
        query: { plan: customersdot_plan, namespace_id: @namespace_id },
        headers: { 'Accept' => 'application/json' }
      )

      Gitlab::Json.parse(response.body).map { |plan| Hashie::Mash.new(plan) }
    rescue => e
      Gitlab::AppLogger.info "Unable to connect to GitLab Customers App #{e}"

      nil
    end

    def customersdot_plan
      strong_memoize(:customersdot_plan) do
        gitlab_plan = Plan.find_by_name(@plan.to_s)
        next @plan unless gitlab_plan

        gitlab_plan.customersdot_name
      end
    end

    def cached
      if plans_data = cache.read(cache_key)
        plans_data
      else
        cache.fetch(cache_key, force: true, expires_in: 1.day) { yield }
      end
    end

    def cache
      Rails.cache
    end

    def cache_key
      if Feature.enabled?(:pnp_subscription_plan_cache_key)
        if @namespace_id.present?
          "pnp-subscription-plan-#{@plan}-#{@namespace_id}"
        else
          "pnp-subscription-plan-#{@plan}"
        end
      elsif Feature.enabled?(:subscription_plan_cache_key)
        if @namespace_id.present?
          "subscription-plan-#{@plan}-#{@namespace_id}"
        else
          "subscription-plan-#{@plan}"
        end
      else
        if @namespace_id.present?
          "subscription-plans-#{@plan}-#{@namespace_id}"
        else
          "subscription-plans-#{@plan}"
        end
      end
    end
  end
end
