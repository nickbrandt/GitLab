# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      module SecurityCompliance
        module MenuItems
          class LicenseCompliance < ::Sidebars::MenuItem
            override :link
            def link
              project_licenses_path(context.project)
            end

            override :active_routes
            def active_routes
              { path: 'projects/licenses#index' }
            end

            override :title
            def title
              _('License Compliance')
            end

            override :render?
            def render?
              can?(context.current_user, :read_licenses, context.project)
            end
          end
        end
      end
    end
  end
end
