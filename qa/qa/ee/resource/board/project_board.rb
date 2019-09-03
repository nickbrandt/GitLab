# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Board
        class ProjectBoard < BaseBoard
          attribute :project do
            QA::Resource::Project.fabricate_via_api! do |project|
              project.name = 'project-with-board'
            end
          end

          def api_get_path
            "/projects/#{project.id}/boards/#{id}"
          end

          def api_post_path
            "/projects/#{project.id}/boards"
          end
        end
      end
    end
  end
end
