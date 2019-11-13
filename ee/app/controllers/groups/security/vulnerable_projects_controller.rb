# frozen_string_literal: true

class Groups::Security::VulnerableProjectsController < Groups::ApplicationController
  include SecurityDashboardsPermissions

  alias_method :vulnerable, :group

  def index
    projects = group.vulnerable_projects.non_archived.without_deleted.with_route

    vulnerable_projects = projects.map do |project|
      ::Security::VulnerableProjectPresenter.new(project)
    end

    render json: VulnerableProjectSerializer.new.represent(vulnerable_projects)
  end
end
