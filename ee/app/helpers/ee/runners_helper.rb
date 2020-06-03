# frozen_string_literal: true
module EE
  module RunnersHelper
    include ::Gitlab::Utils::StrongMemoize

    def show_buy_ci_minutes?(project, namespace)
      return false unless experiment_enabled?(:ci_notification_dot) || experiment_enabled?(:buy_ci_minutes_version_a)

      show_out_of_ci_minutes_notification?(project, namespace)
    end

    def show_ci_minutes_notification_dot?(project, namespace)
      return false unless experiment_enabled?(:ci_notification_dot)

      show_out_of_ci_minutes_notification?(project, namespace)
    end

    private

    def show_out_of_ci_minutes_notification?(project, namespace)
      strong_memoize(:show_out_of_ci_minutes_notification) do
        next unless project&.persisted? || namespace&.persisted?

        ::Ci::Minutes::Notification.new(project, namespace).show?(current_user)
      end
    end
  end
end
