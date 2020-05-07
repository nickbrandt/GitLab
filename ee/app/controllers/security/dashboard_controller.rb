# frozen_string_literal: true

module Security
  class DashboardController < ::Security::ApplicationController
    before_action only: [:show] do
      push_frontend_feature_flag(:first_class_vulnerabilities, default_enabled: true)
    end
  end
end
