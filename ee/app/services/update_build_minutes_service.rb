# frozen_string_literal: true

class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.shared_runners_minutes_limit_enabled?
    return unless build.complete?
    return unless build.duration&.positive?

    if ::Feature.enabled?(:ci_minutes_track_for_public_projects, namespace)
      count_projects_based_on_cost_factors(build)
    else
      legacy_count_non_public_projects(build)
    end
  end

  private

  def count_projects_based_on_cost_factors(build)
    cost_factor = build.runner.minutes_cost_factor(project.visibility_level)
    duration_with_cost_factor = (build.duration * cost_factor).to_i

    return unless duration_with_cost_factor.positive?

    ProjectStatistics.update_counters(project_statistics,
      shared_runners_seconds: duration_with_cost_factor)

    NamespaceStatistics.update_counters(namespace_statistics,
      shared_runners_seconds: duration_with_cost_factor)
  end

  def legacy_count_non_public_projects(build)
    return if project.public?

    ProjectStatistics.update_counters(project_statistics,
      shared_runners_seconds: build.duration)

    NamespaceStatistics.update_counters(namespace_statistics,
      shared_runners_seconds: build.duration)
  end

  def namespace_statistics
    namespace.namespace_statistics || namespace.create_namespace_statistics
  end

  def project_statistics
    project.statistics || project.create_statistics(namespace: project.namespace)
  end

  def namespace
    project.shared_runners_limit_namespace
  end
end
