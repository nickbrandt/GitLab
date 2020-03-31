# frozen_string_literal: true

module EE
  module SystemNotes
    class VulnerabilitiesService < ::SystemNotes::BaseService
      # Called when state is changed for 'vulnerability'
      def change_vulnerability_state
        body = "changed vulnerability status to #{noteable.state}"

        create_note(NoteSummary.new(noteable, project, author, body, action: "vulnerability_#{noteable.state}"))
      end
    end
  end
end
