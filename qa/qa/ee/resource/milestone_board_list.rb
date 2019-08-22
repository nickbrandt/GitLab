# frozen_string_literal: true

module QA
  module EE
    module Resource
      class MilestoneBoardList < QA::Resource::Base
        attribute :id

        attribute :project do
          QA::Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'project-with-milestone-board-list'
          end
        end

        attribute :board do
          QA::EE::Resource::Board.fabricate_via_api! do |b|
            b.project = project
            b.name = 'Product development'
          end
        end

        attribute :project_milestone do
          QA::EE::Resource::ProjectMilestone.fabricate_via_api! do |m|
            m.project = board.project
            m.title = '1.0'
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
            board_id: board.id,
            milestone_id: project_milestone.id
          }
        end
      end
    end
  end
end
