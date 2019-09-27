# frozen_string_literal: true

module EE
  module SystemNotes
    class DesignManagementService < ::SystemNotes::BaseService
      attr_reader :version

      def initialize(version)
        @version = version
        super(noteable: version.issue, project: version.project, author: version.author)
      end

      # Parameters:
      #   - version [DesignManagement::Version]
      #
      # Example Note text:
      #
      #   "added [1 designs](link-to-version)"
      #   "changed [2 designs](link-to-version)"
      #
      # Returns [Array<Note>]: the created Note objects
      def design_version_added
        events = DesignManagement::Action.events
        link_href = self.class.design_version_path(version)

        version.designs_by_event.map do |(event_name, designs)|
          note_data = design_event_note_data(events[event_name])
          icon_name = note_data[:icon]
          n = designs.size

          body = "%s [%d %s](%s)" % [note_data[:past_tense], n, 'design'.pluralize(n), link_href]

          create_note(NoteSummary.new(noteable, project, author, body, action: icon_name))
        end
      end

      # We do not have a named route for DesignManagement::Version, instead
      # we route to `/designs`, with the version in the query parameters.
      # This is because this route is not managed by Rails, but Vue:
      def self.design_version_path(version)
        ::Gitlab::Routing.url_helpers.designs_project_issue_path(
          version.project,
          version.issue,
          version: version.id
        )
      end

      private

      # Take one of the `DesignManagement::Action.events` and
      # return:
      #   * an English past-tense verb.
      #   * the name of an icon used in renderin a system note
      #
      # We do not currently internationalize our system notes,
      # instead we just produce English-language descriptions.
      # See: https://gitlab.com/gitlab-org/gitlab/issues/30408
      # See: https://gitlab.com/gitlab-org/gitlab/issues/14056
      def design_event_note_data(event)
        case event
        when DesignManagement::Action.events[:creation]
          { icon: 'designs_added', past_tense: 'added' }
        when DesignManagement::Action.events[:modification]
          { icon: 'designs_modified', past_tense: 'updated' }
        when DesignManagement::Action.events[:deletion]
          { icon: 'designs_removed', past_tense: 'removed' }
        else
          raise "Unknown event: #{event}"
        end
      end
    end
  end
end
