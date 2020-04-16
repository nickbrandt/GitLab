# frozen_string_literal: true

module Ci
  module Minutes
    class Threshold
      include Gitlab::Allowable

      def initialize(user, context_level)
        @context_level = context_level
        @user = user
      end

      def warning_reached?
        show_limit? && context_level.shared_runners_remaining_minutes_below_threshold?
      end

      def alert_reached?
        show_limit? && context_level.shared_runners_minutes_used?
      end

      private

      attr_reader :user, :context_level

      def show_limit?
        context_level.shared_runners_minutes_limit_enabled? && can_see_status?
      end

      def can_see_status?
        context_level.is_a?(Namespace) || can?(user, :create_pipeline, context_level)
      end
    end
  end
end
