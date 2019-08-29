# frozen_string_literal: true

module Projects
  class AlertNotificationsController < Projects::ApplicationController
    respond_to :json

    skip_before_action :project

    prepend_before_action :repository, :project_without_auth

    def create
      head :ok
    end

    private

    def project_without_auth
      return @project if @project

      namespace = params[:namespace_id]
      id = params[:project_id]

      @project = Project.find_by_full_path("#{namespace}/#{id}")
    end
  end
end
