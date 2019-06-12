# frozen_string_literal: true

module InsightsFeature
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  DEFAULT_INSIGHT_CONFIG = 'ee/fixtures/insights/default.yml'

  def insights_available?
    feature_available?(:insights)
  end

  def insights_config(follow_group: true)
    case self
    when Group
      # When there's a config file, we use it regardless it's valid or not
      if insight&.project&.project_insights_config_yaml
        insight.project.insights_config(follow_group: false)
      else # When there's nothing, then we use the default
        default_insights_config
      end
    when Project
      yaml = project_insights_config_yaml

      # When there's a config file, we use it regardless it's valid or not
      if yaml
        strong_memoize(:insights_config) do
          ::Gitlab::Config::Loader::Yaml.new(yaml).load!
        rescue Gitlab::Config::Loader::FormatError
          nil
        end
      # When we're following the group and there's a group then we use it
      elsif follow_group && group
        group.insights_config
      # A project might not have a group, then we just use the default
      else
        default_insights_config
      end
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

  def project_insights_config_yaml
    strong_memoize(:project_insights_config_yaml) do
      next if repository.empty?

      repository.insights_config_for(repository.root_ref)
    end
  end
end
