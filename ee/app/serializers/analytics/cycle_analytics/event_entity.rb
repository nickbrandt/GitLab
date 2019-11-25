# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class EventEntity < Grape::Entity
      expose :name
      expose :identifier
      expose :type
      expose :can_be_start_event?, as: :can_be_start_event
      expose :allowed_end_events
      expose :label_based?, as: :label_based

      private

      def type
        'simple'
      end

      def can_be_start_event?
        pairing_rules.has_key?(object)
      end

      def allowed_end_events
        pairing_rules.fetch(object, []).map(&:identifier)
      end

      def pairing_rules
        Gitlab::Analytics::CycleAnalytics::StageEvents.pairing_rules
      end
    end
  end
end
