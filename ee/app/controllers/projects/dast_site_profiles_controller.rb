# frozen_string_literal: true

module Projects
  class DastSiteProfilesController < Projects::ApplicationController
    before_action :authorize_read_on_demand_scans!

    def new
    end

    def edit
      @site_profile = @project
        .dast_site_profiles
        .with_dast_site
        .find(params[:id])
    end

    private

    def authorize_read_on_demand_scans!
      access_denied! unless can?(current_user, :read_on_demand_scans, project)
    end
  end
end
