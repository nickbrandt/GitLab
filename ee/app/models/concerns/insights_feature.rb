# frozen_string_literal: true

module InsightsFeature
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  DEFAULT_INSIGHT_CONFIG = 'ee/fixtures/insights/default.yml'

  def insights_available?
    feature_available?(:insights)
  end

  def insights_config_project
    strong_memoize(:insights_config_project) do
      case self
      when Group
        insight&.project
      when Project
        if insights_config_yaml
          self
        else
          group&.insights_config_project
        end
      end
    end
  end

  def insights_config
    strong_memoize(:insights_config) do
      yaml = insights_config_project&.insights_config_yaml

      if yaml
        ::Gitlab::Config::Loader::Yaml.new(yaml).load!
      else
        default_insights_config
      end
    rescue Gitlab::Config::Loader::FormatError
      nil
    end
  end

  def default_insights_config
    strong_memoize(:default_insights_config) do
      yaml = File.read(Rails.root.join(DEFAULT_INSIGHT_CONFIG).to_s)
      ::Gitlab::Config::Loader::Yaml.new(yaml).load!
    rescue Gitlab::Config::Loader::FormatError
      nil
    end
  end

  protected

  def insights_config_yaml
    raise NotImplementedError unless is_a?(Project)

    strong_memoize(:insights_config_yaml) do
      next if repository.empty?

      repository.insights_config_for(repository.root_ref)
    end
  end
end
