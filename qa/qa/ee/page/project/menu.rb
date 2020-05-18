# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend QA::Page::Project::SubMenus::Common
              prepend SubMenus::SecurityCompliance
              prepend SubMenus::Packages
              prepend SubMenus::Project
              prepend SubMenus::Repository
              prepend SubMenus::Settings
            end
          end
        end
      end
    end
  end
end
