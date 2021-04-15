# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class ScanPolicies < ::Sidebars::MenuItem
            override :link
            def link
              project_security_policy_path(context.project)
            end

            override :active_routes
            def active_routes
              { controller: ['projects/security/policies'] }
            end

            override :title
            def title
              _('Scan Policies')
            end

            override :render?
            def render?
              can?(context.current_user, :security_orchestration_policies, context.project) &&
                Feature.enabled?(:security_orchestration_policies_configuration, context.project)
            end
          end
        end
      end
    end
  end
end
