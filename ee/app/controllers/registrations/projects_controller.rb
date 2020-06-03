# frozen_string_literal: true

module Registrations
  class ProjectsController < ApplicationController
    layout 'checkout'

    before_action :check_experiment_enabled
    before_action :find_namespace, only: :new

    def new
      @project = Project.new(namespace: @namespace)
    end

    def create
      @project = ::Projects::CreateService.new(current_user, project_params).execute

      if @project.saved?
        redirect_to project_path(@project)
      else
        render :new
      end
    end

    private

    def check_experiment_enabled
      access_denied! unless experiment_enabled?(:onboarding_issues)
    end

    def find_namespace
      @namespace = Namespace.find_by_id(params[:namespace_id])

      access_denied! unless can?(current_user, :create_projects, @namespace)
    end

    def project_params
      params.require(:project).permit(project_params_attributes)
    end

    def project_params_attributes
      [
        :namespace_id,
        :name,
        :path,
        :visibility_level
      ]
    end
  end
end
