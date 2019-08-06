# frozen_string_literal: true

module EE
  module TabHelper
    extend ::Gitlab::Utils::Override

    override :project_tab_class
    def project_tab_class
      if controller.controller_name == 'push_rules'
        'active'
      else
        super
      end
    end

    def analytics_controllers
      ['analytics/productivity_analytics', 'analytics/cycle_analytics']
    end
  end
end
