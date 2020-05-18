# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module Packages
            extend QA::Page::PageConcern

            def self.prepended(base)
              base.class_eval do
                view 'ee/app/views/layouts/nav/sidebar/_project_packages_link.html.haml' do
                  element :packages_link
                end
              end
            end

            def click_packages_link
              within_sidebar do
                click_element :packages_link
              end
            end
          end
        end
      end
    end
  end
end
