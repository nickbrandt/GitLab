# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Menu
          prepend QA::Page::Project::SubMenus::Common
          prepend SubMenus::SecurityCompliance
          prepend SubMenus::Packages
          prepend SubMenus::Project
          prepend SubMenus::Settings
        end
      end
    end
  end
end
