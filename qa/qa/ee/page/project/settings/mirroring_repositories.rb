# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MirroringRepositories
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/mirrors/_mirror_repos_form.html.haml' do
                  element :mirror_direction
                end
              end
            end
          end
        end
      end
    end
  end
end
