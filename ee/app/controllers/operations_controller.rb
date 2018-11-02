# frozen_string_literal: true

class OperationsController < ApplicationController
  layout 'fullscreen'

  before_action :authorize_read_operations_dashboard!

  respond_to :json, only: [:list]

  def index
  end

  def list
    projects = load_projects(current_user)

    render json: { projects: serialize_as_json(projects) }
  end

  def create
    project_ids = params['project_ids']

    result = add_projects(current_user, project_ids)

    render json: {
      added: result.added_project_ids,
      duplicate: result.duplicate_project_ids,
      invalid: result.invalid_project_ids
    }
  end

  def destroy
    project_id = params['project_id']

    if remove_project(current_user, project_id)
      head :ok
    else
      head :no_content
    end
  end

  private

  def authorize_read_operations_dashboard!
    render_404 unless can?(current_user, :read_operations_dashboard)
  end

  def load_projects(current_user)
    Dashboard::Operations::ListService.new(current_user).execute
  end

  def add_projects(current_user, project_ids)
    UsersOpsDashboardProjects::CreateService.new(current_user).execute(project_ids)
  end

  def remove_project(current_user, project_id)
    UsersOpsDashboardProjects::DestroyService.new(current_user).execute(project_id)
  end

  def serialize_as_json(projects)
    DashboardOperationsSerializer.new(current_user: current_user).represent(projects).as_json
  end
end
