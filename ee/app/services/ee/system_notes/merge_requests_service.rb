# frozen_string_literal: true

module EE
  module SystemNotes
    module MergeRequestsService
      def unapprove_mr
        body = "unapproved this merge request"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'unapproved'))
      end
    end
  end
end
