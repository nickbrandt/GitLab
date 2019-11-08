module SourcegraphGon
  extend ActiveSupport::Concern

  def push_sourcegraph_gon
    return unless enabled?

    gon.push({
      sourcegraph_enabled: true,
      sourcegraph_url: Gitlab::CurrentSettings.sourcegraph_url
    })
  end

  private 

  def enabled?
    current_user&.sourcegraph_enabled && project_enabled?
  end

  def project_enabled?
    return false unless project && Gitlab::Sourcegraph.feature_enabled?(project)
    return project.public? if Gitlab::CurrentSettings.sourcegraph_public_only

    true
  end

  def project
    @target_project || @project  
  end
end
