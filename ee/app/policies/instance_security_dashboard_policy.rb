# frozen_string_literal: true

class InstanceSecurityDashboardPolicy < BasePolicy
  rule { ~anonymous }.enable :read_instance_security_dashboard
end
