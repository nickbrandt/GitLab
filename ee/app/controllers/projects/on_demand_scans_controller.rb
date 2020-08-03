# frozen_string_literal: true

module Projects
  class OnDemandScansController < Projects::ApplicationController
    before_action do
      authorize_read_on_demand_scans!
      push_frontend_feature_flag(:security_on_demand_scans_site_profiles_feature_flag, project)
    end

    def index
    end

    private

    def authorize_read_on_demand_scans!
      access_denied! unless can?(current_user, :read_on_demand_scans, project)
    end
  end
end
