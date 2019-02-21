# frozen_string_literal: true

module EE
  module API
    module Helpers
      module NotesHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :noteable_types
          def noteable_types
            [::Epic, *super]
          end
        end

        def find_group_epic(id)
          finder_params = { group_id: user_group.id }
          EpicsFinder.new(current_user, finder_params).find(id)
        end

        def noteable_parent_str(noteable_class)
          parent_class = ::Epic <= noteable_class ? ::Group : ::Project

          parent_class.to_s.underscore
        end
      end
    end
  end
end
