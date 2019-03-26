# frozen_string_literal: true

module InsightsFeature
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  def insights_available?
    beta_feature_available?(:insights)
  end

  def insights_config
    case self
    when Group
      insight&.project&.insights_config
    when Project
      return if repository.empty?

      insights_config_yml = repository.insights_config_for(repository.root_ref)
      return unless insights_config_yml

      strong_memoize(:insights_config) do
        ::Gitlab::Config::Loader::Yaml.new(insights_config_yml).load!
      rescue Gitlab::Config::Loader::FormatError
        nil
      end
    end
  end
end
