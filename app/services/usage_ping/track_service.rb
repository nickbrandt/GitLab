# frozen_string_literal: true

module UsagePing
  class TrackService < ::BaseContainerService
    SUPPORTED_EVENTS = {
      'static_site_editor_create_commit' => -> { Gitlab::UsageDataCounters::StaticSiteEditorCounter.increment_commits_count },
      'static_site_editor_create_merge_request' => -> { Gitlab::UsageDataCounters::StaticSiteEditorCounter.increment_merge_requests_count }
    }.freeze

    def execute
      track_event!

      ServiceResponse.success
    rescue KeyError
      ServiceResponse.error(message: 'Unsupported event')
    end

    private

    def track_event!
      SUPPORTED_EVENTS.fetch(container).call
    end
  end
end
