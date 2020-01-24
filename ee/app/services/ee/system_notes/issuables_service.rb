# frozen_string_literal: true
module EE
  module SystemNotes
    module IssuablesService
      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "marked this issue as related to gitlab-foss#9001"
      #
      # Returns the created Note object
      def relate_issue(noteable_ref)
        body = "marked this issue as related to #{noteable_ref.to_reference(noteable.project)}"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
      end

      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "removed the relation with gitlab-foss#9001"
      #
      # Returns the created Note object
      def unrelate_issue(noteable_ref)
        body = "removed the relation with #{noteable_ref.to_reference(noteable.project)}"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'unrelate'))
      end

      # Called when the weight of a Noteable is changed
      #
      # Example Note text:
      #
      #   "removed the weight"
      #
      #   "changed weight to 4"
      #
      # Returns the created Note object
      def change_weight_note
        body = noteable.weight ? "changed weight to **#{noteable.weight}**" : 'removed the weight'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'weight'))
      end

      def auto_resolve_prometheus_alert
        body = 'automatically closed this issue because the alert resolved.'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'closed'))
      end
    end
  end
end
