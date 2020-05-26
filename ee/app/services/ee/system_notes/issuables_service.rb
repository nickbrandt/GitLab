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

      # Called when the health_status of an Issue is changed
      #
      # Example Note text:
      #
      #   "removed the health status"
      #
      #   "changed health status to at risk"
      #
      # Returns the created Note object
      def change_health_status_note
        health_status = noteable.health_status&.humanize(capitalize: false)
        body = health_status ? "changed health status to **#{health_status}**" : 'removed the health status'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'health_status'))
      end

      # Called when the an issue is published to a project's
      # status page application
      #
      # Example Note text:
      #
      #   "published this issue to the status page"
      #
      # Returns the created Note object
      def publish_issue_to_status_page
        body = 'published this issue to the status page'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'published'))
      end

      # Called when the iteration of a Noteable is changed
      #
      # iteration - Iteration being assigned, or nil
      #
      # Example Note text:
      #
      #   "removed iteration"
      #
      #   "changed iteration to 7.11"
      #
      # Returns the created Note object
      def change_iteration(iteration)
        body = iteration.nil? ? 'removed iteration' : "changed iteration to #{iteration.to_reference(project, format: :id)}"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'iteration'))
      end
    end
  end
end
