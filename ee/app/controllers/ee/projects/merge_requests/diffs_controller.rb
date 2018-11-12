# frozen_string_literal: true

module EE
  module Projects
    module MergeRequests
      module DiffsController
        extend ActiveSupport::Concern

        def renderable_notes
          draft_notes =
            if current_user
              merge_request.draft_notes.authored_by(current_user)
            else
              []
            end

          super.concat(draft_notes)
        end
      end
    end
  end
end
