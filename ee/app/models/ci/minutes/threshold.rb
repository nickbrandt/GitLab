# frozen_string_literal: true

module Ci
  module Minutes
    class Threshold
      include ::Gitlab::Utils::StrongMemoize

      def initialize(context)
        @context = context
      end

      def warning_reached?
        show_limit? && context.shared_runners_remaining_minutes_below_threshold?
      end

      def alert_reached?
        show_limit? && context.shared_runners_minutes_used?
      end

      private

      attr_reader :context

      def show_limit?
        strong_memoize(:show_limit) do
          context.shared_runners_minutes_limit_enabled? && context.can_see_status?
        end
      end
    end
  end
end
