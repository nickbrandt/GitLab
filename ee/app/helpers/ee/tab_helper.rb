# frozen_string_literal: true

module EE
  module TabHelper
    extend ::Gitlab::Utils::Override

    def analytics_controllers
      ['analytics/productivity_analytics', 'analytics/cycle_analytics']
    end
  end
end
