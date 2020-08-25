# frozen_string_literal: true

module Projects
  class OnDemandScansController < Projects::ApplicationController
    before_action do
      authorize_read_on_demand_scans!
      push_frontend_feature_flag(:security_on_demand_scans_site_profiles_feature_flag, project, default_enabled: true)
    end

    def index
    end
  end
end
