# frozen_string_literal: true

module Projects
  class OnDemandScansController < Projects::ApplicationController
    before_action do
      authorize_read_on_demand_scans!
    end

    def index
    end
  end
end
