# frozen_string_literal: true

module Gitlab
  module Alerting
    class NotificationPayloadParser
      def initialize(payload)
        @payload = payload.to_h.with_indifferent_access
      end

      def self.call(payload)
        new(payload).call
      end

      def call
        {
          'annotations' => {
            'title' => payload[:title]
          },
          'startsAt' => payload[:starts_at]
        }
      end

      private

      attr_reader :payload
    end
  end
end
