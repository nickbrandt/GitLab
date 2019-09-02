# frozen_string_literal: true

module QA
  module EE
    module Resource
      module BoardList
        class MilestoneBoardList < BaseBoardList
          attribute :project_milestone do
            QA::EE::Resource::ProjectMilestone.fabricate_via_api! do |m|
              m.project = board.project
              m.title = '1.0'
            end
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
end
