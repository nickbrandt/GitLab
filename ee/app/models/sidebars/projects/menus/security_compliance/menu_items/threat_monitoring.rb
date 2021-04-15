# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class ThreatMonitoring < ::Sidebars::MenuItem
            override :link
            def link
              project_threat_monitoring_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: ['projects/threat_monitoring'] }
            end

            override :title
            def title
              _('Threat Monitoring')
            end

            override :render?
            def render?
              can?(context.current_user, :read_threat_monitoring, context.project)
            end
          end
        end
      end
    end
  end
end
