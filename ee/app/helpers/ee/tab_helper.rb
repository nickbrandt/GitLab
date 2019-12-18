# frozen_string_literal: true

module EE
  module TabHelper
    extend ::Gitlab::Utils::Override

    def analytics_controllers
      ['analytics/productivity_analytics', 'analytics/cycle_analytics', 'instance_statistics/dev_ops_score', 'instance_statistics/cohorts']
    end
  end
end
