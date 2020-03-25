# frozen_string_literal: true

module EE
  module SystemNotes
    class VulnerabilitiesService < ::SystemNotes::BaseService
      # Called when state is changed for 'vulnerability'
      def change_vulnerability_state
        body = "changed vulnerability status to #{noteable.state}"
        action = noteable.confirmed? ? 'opened' : 'closed'

        create_note(NoteSummary.new(noteable, project, author, body, action: action))
      end
    end
  end
end
