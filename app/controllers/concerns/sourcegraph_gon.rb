module SourcegraphGon
  extend ActiveSupport::Concern

  def push_sourcegraph_gon
    return unless can?(current_user, :access_sourcegraph, sourcegraph_project)

    gon.push({
      sourcegraph_enabled: true,
      sourcegraph_url: Gitlab::CurrentSettings.sourcegraph_url
    })
  end

  private

  def sourcegraph_project
    @target_project || project
  end
end
