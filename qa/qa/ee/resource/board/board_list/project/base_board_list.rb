# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Board
        module BoardList
          module Project
            class BaseBoardList < QA::Resource::Base
              attribute :id

              attribute :project do
                QA::Resource::Project.fabricate_via_api! do |project|
                  project.name = 'project-with-board-list'
                end
              end

              attribute :board do
                QA::EE::Resource::Board::ProjectBoard.fabricate_via_api! do |project_board|
                  project_board.project = project
                  project_board.name = 'Downstream'
                end
              end

              def resource_web_url(resource)
                super
              rescue ResourceURLMissingError
                # this particular resource does not expose a web_url property
              end

              def api_get_path
                "/projects/#{board.project.id}/boards/#{board.id}/lists/#{id}"
              end

              def api_post_path
                "/projects/#{board.project.id}/boards/#{board.id}/lists"
              end

              def api_post_body
                {
                  board_id: board.id
                }
              end
            end
          end
        end
      end
    end
  end
end
