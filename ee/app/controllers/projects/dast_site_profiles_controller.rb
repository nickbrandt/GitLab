# frozen_string_literal: true

module Projects
  class DastSiteProfilesController < Projects::ApplicationController
    before_action do
      authorize_read_on_demand_scans!
      push_frontend_feature_flag(:security_on_demand_scans_site_validation, @project)
    end

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
