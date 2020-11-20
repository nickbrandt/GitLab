# frozen_string_literal: true

class Projects::UsagePingController < Projects::ApplicationController
  include RedisTracking

  before_action :authenticate_user!

  feature_category :collection

  track_redis_hll_event :sse_commits_count, name: 'g_edit_by_sse', feature: :track_editor_edit_actions, feature_default_enabled: true

  def web_ide_clientside_preview
    return render_404 unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

    Gitlab::UsageDataCounters::WebIdeCounter.increment_previews_count

    head(200)
  end

  def web_ide_pipelines_count
    Gitlab::UsageDataCounters::WebIdeCounter.increment_pipelines_count

    head(200)
  end

  def sse_commits_count
    Gitlab::UsageDataCounters::StaticSiteEditorCounter.increment_commits_count

    head(200)
  end
end
