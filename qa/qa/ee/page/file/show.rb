# frozen_string_literal: true

module QA
  module EE
    module Page
      module File
        module Show
          def self.prepended(page)
            page.module_eval do
              view 'ee/app/views/projects/blob/_owners.html.haml' do
                element :file_owner_content
                element :link_file_owner
              end
            end
          end
        end
      end
    end
  end
end
