# frozen_string_literal: true

class InstancePolicy < BasePolicy
  rule { ~anonymous }.enable :read_instance_security_dashboard
end
