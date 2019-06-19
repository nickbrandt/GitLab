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

        def find_noteable(parent_type, parent_id, noteable_type, noteable_id)
          if noteable_type == ::Epic
            EpicsFinder.new(current_user, group_id: parent_id).find(noteable_id)
          else
            super
          end
        end
      end
    end
  end
end
