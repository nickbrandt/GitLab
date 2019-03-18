# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Menu
          def self.prepended(page)
            page.module_eval do
              view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
                element :link_license_menu
                element :link_geo_menu
                element :admin_settings_template_item
              end
            end
          end

          def go_to_geo_nodes
            click_element :link_geo_menu
          end

          def go_to_license
            click_element :link_license_menu
          end

          def go_to_template_settings
            hover_settings do
              within_submenu do
                click_element :admin_settings_template_item
              end
            end
          end
        end
      end
    end
  end
end
