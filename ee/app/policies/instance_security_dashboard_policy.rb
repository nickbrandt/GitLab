# frozen_string_literal: true

class InstanceSecurityDashboardPolicy < BasePolicy
  rule { ~anonymous }.policy do
    enable :read_instance_security_dashboard
    enable :create_vulnerability_export
  end
end
