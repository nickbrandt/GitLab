# frozen_string_literal: true

module SourcegraphHelper
  def sourcegraph_help_message
    return unless Gitlab::CurrentSettings.sourcegraph_enabled

    if Gitlab::Sourcegraph.feature_conditional?
      _("This feature is experimental and has been limited to only certain projects.")
    elsif Gitlab::CurrentSettings.sourcegraph_public_only
      _("This feature is experimental and also limited to only public projects.")
    else
      _("This feature is experimental.")
    end
  end
end
