# frozen_string_literal: true

class Groups::Security::StaleProjectsController < Groups::ApplicationController
  include SecurityDashboardsPermissions

  alias_method :vulnerable, :group

  def index
    projects = group.projects.non_archived.without_deleted.with_route

    latest_pipelines = projects.reduce([]) do |acc, project|
      pipeline = project.latest_pipeline_for_ref

      if pipeline.present?
        acc << pipeline
      end

      acc
    end

    latest_pipelines_security_jobs = latest_pipelines.map do |pipeline|
      ::Security::JobsFinder.new(pipeline: pipeline).execute
    end

    projects_with_jobs = projects.map do |project|
      project_jobs = latest_pipelines_security_jobs.find do |jobs|
        jobs.first.project_id == project.id
      end

      [project, project_jobs || []]
    end

    stale_projects = projects_with_jobs.reduce([]) do |acc, (project, jobs)|
      stale_project = ::Security::StaleProjectPresenter.new(project, latest_security_jobs: jobs)

      if !stale_project.unconfigured_scans.empty? || !stale_project.out_of_date_scans.empty?
        acc << stale_project
      end

      acc
    end

    render json: StaleProjectSerializer.new.represent(stale_projects)
  end

  private

  def stale_projects
    group.projects
    # joins builds
    # where there are no builds with security reports
    # OR where the latest successful builds with security reports finished 6 or more days ago
  end
end
