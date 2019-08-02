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

        def add_parent_to_finder_params(finder_params, noteable_type, parent_id)
          if noteable_type.name.underscore == 'epic'
            finder_params[:group_id] = parent_id
          else
            super
          end
        end
      end
    end
  end
end
