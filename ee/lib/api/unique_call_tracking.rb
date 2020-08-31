# frozen_string_literal: true

module API
  class UniqueCallTracking < Grape::Middleware::Base
    def visitor_id
      return context.session[:visitor_id] if context.session[:visitor_id].present?
      return unless context.current_user

      uuid = SecureRandom.uuid
      context.session[:visitor_id] = uuid
      uuid
    end

    def track_redis_hll_event(event_name, feature)
      return unless feature_enabled?(feature)
      return unless visitor_id

      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(visitor_id, event_name)
    end

    def after
      track_redis_hll_event(@options[:event_name], @options[:feature])
      nil
    end

    private

    def feature_enabled?(feature = :track_unique_visits)
      Feature.enabled?(feature) && Gitlab::CurrentSettings.usage_ping_enabled?
    end
  end
end
