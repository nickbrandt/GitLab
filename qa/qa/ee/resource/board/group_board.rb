# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Board
        class GroupBoard < BaseBoard
          attribute :group do
            QA::Resource::Group.fabricate_via_api! do |group|
              group.name = 'group-with-board'
            end
          end

          def api_get_path
            "/groups/#{group.id}/boards/#{id}"
          end

          def api_post_path
            "/groups/#{group.id}/boards"
          end
        end
      end
    end
  end
end
