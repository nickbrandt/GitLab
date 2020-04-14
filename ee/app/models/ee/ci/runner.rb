# frozen_string_literal: true

module EE
  module Ci
    module Runner
      def tick_runner_queue
        ::Gitlab::Database::LoadBalancing::Sticking.stick(:runner, id)

        super
      end

      def minutes_cost_factor(access_level)
        return 0.0 unless instance_type?

        case access_level
        when ::Gitlab::VisibilityLevel::PUBLIC
          public_projects_minutes_cost_factor
        else # Gitlab::VisibilityLevel::PRIVATE/INTERNAL
          private_projects_minutes_cost_factor
        end
      end

      def visibility_levels_without_minutes_quota
        ::Gitlab::VisibilityLevel.options.values.reject do |visibility_level|
          minutes_cost_factor(visibility_level).positive?
        end
      end
    end
  end
end
