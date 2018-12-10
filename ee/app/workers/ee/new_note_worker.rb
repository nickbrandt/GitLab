# frozen_string_literal: true

module EE
  module NewNoteWorker
    extend ActiveSupport::Concern

    private

    # If a note belongs to a review
    # We do not want to send a standalone
    # notification
    def skip_notification?(note)
      note.review.present?
    end
  end
end
