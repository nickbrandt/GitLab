# frozen_string_literal: true

module InsightsFeature
  extend ActiveSupport::Concern

  # This allows to:
  #   1. Disable the :insights by default even if the license allows it
  #   1. Enable the Insights feature for an arbitrary group/project
  # Once we're ready to release the feature, we could just replace
  # `{group,project}.insights_available?` with
  # `{group,project}.feature_available?(:insights)` and remove this module.
  def insights_available?
    ::Feature.enabled?(:insights, self) && feature_available?(:insights)
  end

  def insights_config
    return self.insight.project.insights_config if self.respond_to?(:insight) && self.insight
    return unless self.respond_to?(:repository)
    return if self.repository.empty?

    insights_config_yml = self.repository.insights_config_for(self.repository.root_ref)
    return unless insights_config_yml

    strong_memoize(:insights_config) do
      ::Gitlab::Config::Loader::Yaml.new(insights_config_yml).load!
    end
  rescue Gitlab::Config::Loader::FormatError
    nil
  end
end
