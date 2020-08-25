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
  end
end
