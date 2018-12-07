# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::Security::ApplicationController
  layout 'group'

  before_action do
    push_frontend_feature_flag(:group_security_dashboard_history, group)
  end
end
