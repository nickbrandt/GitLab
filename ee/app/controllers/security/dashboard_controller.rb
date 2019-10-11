# frozen_string_literal: true

module Security
  class DashboardController < ::Security::ApplicationController
    def show
      head :ok
    end
  end
end
