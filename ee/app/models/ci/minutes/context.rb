# frozen_string_literal: true

module Ci
  module Minutes
    class Context
      delegate :shared_runners_remaining_minutes_below_threshold?,
               :shared_runners_minutes_used?,
               :shared_runners_minutes_limit_enabled?, to: :level
      delegate :name, to: :namespace, prefix: true
      delegate :last_ci_minutes_usage_notification_level,
               :shared_runners_remaining_minutes_percent, to: :namespace

      def initialize(user, project, namespace)
        @user = user
        @project = project
        @namespace = project&.shared_runners_limit_namespace || namespace
        @level = project || namespace
      end

      def can_see_status?
        if project
          user.can?(:create_pipeline, project)
        else
          namespace.all_pipelines.for_user(user).any?
        end
      end

      private

      attr_reader :project, :user, :level, :namespace
    end
  end
end
