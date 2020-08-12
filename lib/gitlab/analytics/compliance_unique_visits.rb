# frozen_string_literal: true

module Gitlab
  module Analytics
    class ComplianceUniqueVisits < UsageDataCounters::HLLRedisCounter
      KNOWN_EVENTS = Set[
        'g_compliance_dashboard',
        'g_compliance_audit_events',
        'i_compliance_credential_inventory',
        'i_compliance_audit_events'
      ].freeze

      KEY_EXPIRY_LENGTH = 12.weeks
      REDIS_SLOT = 'compliance'.freeze

      def track_visit(visitor_id, target_id, time = Time.zone.now)
        track_event(visitor_id, target_id, time)
      end

      # Returns number of unique visitors for given targets in given time frame
      #
      # @param [String, Array[<String>]] targets ids of targets to count visits on
      # @param [ActiveSupport::TimeWithZone] start_week start of time frame
      # @param [Integer] weeks time frame length in weeks
      # @return [Integer] number of unique visitors
      def unique_visits_for(targets:, start_week: 7.days.ago, weeks: 1)
        unique_events(events: targets, start_week: start_week, weeks: weeks)
      end
    end
  end
end
