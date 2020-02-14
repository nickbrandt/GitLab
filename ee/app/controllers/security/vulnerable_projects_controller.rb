# frozen_string_literal: true

class Security::VulnerableProjectsController < Security::ApplicationController
  def index
    vulnerable_projects = ::Security::VulnerableProjectsFinder.new(projects).execute

    presented_projects = vulnerable_projects.map do |project|
      ::Security::VulnerableProjectPresenter.new(project)
    end

    render json: VulnerableProjectSerializer.new.represent(presented_projects)
  end

  private

  def projects
    vulnerable.projects.non_archived.without_deleted.with_route
  end
end
