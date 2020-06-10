# frozen_string_literal: true

module Projects
  class OnDemandScansController < Projects::ApplicationController
    before_action :authorize_read_on_demand_scans!

    def index
    end

    private

    def authorize_read_on_demand_scans!
      access_denied! unless can?(current_user, :read_on_demand_scans, project)
    end
  end
end
