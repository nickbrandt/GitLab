# frozen_string_literal: true

class Groups::Security::VulnerableProjectsController < Groups::ApplicationController
  include SecurityDashboardsPermissions

  alias_method :vulnerable, :group

  def index
    vulnerable_projects = ::Security::VulnerableProjectsFinder.new(projects).execute

    presented_projects = vulnerable_projects.map do |project|
      ::Security::VulnerableProjectPresenter.new(project)
    end

    render json: VulnerableProjectSerializer.new.represent(presented_projects)
  end

  private

  def projects
    ::Project.for_group_and_its_subgroups(group).non_archived.without_deleted.with_route
  end
end
