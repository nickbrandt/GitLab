# frozen_string_literal: true

module EE
  module SystemNotes
    module MergeRequestsService
      # Called when the merge request is approved by user
      #
      # Example Note text:
      #
      #   "approved this merge request"
      #
      # Returns the created Note object
      def approve_mr
        body = "approved this merge request"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'approved'))
      end

      def unapprove_mr
        body = "unapproved this merge request"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'unapproved'))
      end
    end
  end
end
