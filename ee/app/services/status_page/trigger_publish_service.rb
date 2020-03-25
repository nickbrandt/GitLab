# frozen_string_literal: true

module StatusPage
  # Triggers a background job to publish of incidents to the status page.
  #
  # This service determines whether the passed +triggered_by+ (issue, note,
  # or emoji) is eligible to kick-off the publish process.
  class TriggerPublishService
    include Gitlab::Utils::StrongMemoize

    # Publish status page only if the following issue attributes have changed.
    # If we expose new fields in +StatusPage::IncidentEntity+ add them to
    # this list too.
    #
    # Note: `closed_by_id` is needed because we cannot rely on `state_id` in
    # Issues::CloseService
    PUBLISH_WHEN_ISSUE_CHANGED =
      %w[title description confidential state_id closed_by_id].freeze

    def initialize(project, user, triggered_by)
      @project = project
      @user = user
      @triggered_by = triggered_by
    end

    def execute
      return unless can_publish?
      return unless status_page_enabled?
      return unless issue_id

      StatusPage::PublishWorker.perform_async(user.id, project.id, issue_id)
    end

    private

    attr_reader :user, :project, :triggered_by

    def can_publish?
      user&.can?(:publish_status_page, project)
    end

    def status_page_enabled?
      project.status_page_setting&.enabled?
    end

    def issue_id
      strong_memoize(:issue_id) { eligable_issue_id }
    end

    def eligable_issue_id
      case triggered_by
      when Issue then eligable_issue_id_from_issue
      else
        raise ArgumentError, "unsupported trigger type #{triggered_by.class}"
      end
    end

    def eligable_issue_id_from_issue
      changes = triggered_by.previous_changes.keys & PUBLISH_WHEN_ISSUE_CHANGED

      return if changes.none?
      # Ignore updates for already confidential issues
      # Note: Issues becoming confidential _will_ be unpublished.
      return if triggered_by.confidential? && changes.exclude?('confidential')

      triggered_by.id
    end
  end
end
