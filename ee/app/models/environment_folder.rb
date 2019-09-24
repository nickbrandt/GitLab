# frozen_string_literal: true

class EnvironmentFolder
  attr_reader :last_environment, :size

  delegate :project, to: :last_environment

  def self.find_for_projects(projects)
    environments = ::Environment.where(project: projects).available
    t = ::Environment.arel_table

    folder_data = environments
      .group('COALESCE(environment_type, name), project_id')
      .pluck(t[:id].maximum, t[:id].count)

    environments_by_id = environments
      .id_in(folder_data.map { |(env_id, _)| env_id })
      .includes(:project, last_deployment: [:project, deployable: :user])
      .index_by(&:id)

    folders = folder_data.map do |(environment_id, count)|
      environment = environments_by_id[environment_id]
      next unless environment

      new(environments_by_id[environment_id], count)
    end

    projects_with_folders = folders.compact.group_by(&:project)
    projects.map { |p| { p => [] } }.reduce({}, :merge).merge(projects_with_folders)
  end

  def initialize(last_environment, size)
    @last_environment = last_environment
    @size = size
  end

  def within_folder?
    last_environment.environment_type.present? || size > 1
  end
end
