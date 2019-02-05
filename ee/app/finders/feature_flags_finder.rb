# frozen_string_literal: true

class FeatureFlagsFinder
  attr_reader :project, :feature_flags, :params, :current_user

  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @feature_flags = project.operations_feature_flags
    @params = params
  end

  def execute
    unless Ability.allowed?(current_user, :read_feature_flag, project)
      return Operations::FeatureFlag.none
    end

    items = feature_flags
    items = by_scope(items)
    items = for_list(items)

    items.ordered
  end

  private

  def by_scope(items)
    case params[:scope]
    when 'enabled'
      items.enabled
    when 'disabled'
      items.disabled
    else
      items
    end
  end

  def for_list(items)
    if Feature.enabled?(:feature_flags_environment_scope, project)
      items.for_list
    else
      items
    end
  end
end
