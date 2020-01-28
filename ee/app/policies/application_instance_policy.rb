# frozen_string_literal: true

class ApplicationInstancePolicy < BasePolicy
  rule { ~anonymous }.enable :read_application_instance_security_dashboard
end
