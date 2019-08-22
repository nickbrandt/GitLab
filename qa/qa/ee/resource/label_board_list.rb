# frozen_string_literal: true

module QA
  module EE
    module Resource
      class LabelBoardList < QA::Resource::Base
        attribute :id

        attribute :project do
          QA::Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'project-with-label-board-list'
          end
        end

        attribute :board do
          QA::EE::Resource::Board.fabricate_via_api! do |b|
            b.project = project
            b.name = 'Downstream'
          end
        end

        attribute :label do
          QA::Resource::Label.fabricate_via_api! do |l|
            l.project = board.project
            l.title = 'Doing'
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
            label_id: label.id
          }
        end
      end
    end
  end
end
