# frozen_string_literal: true

module Groups
  module Security
    module DashboardHelper
      def can_read_group_security_dashboard?(group)
        can?(current_user, :read_group_security_dashboard, group)
      end
    end
  end
end
