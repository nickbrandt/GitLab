# frozen_string_literal: true

module EE
  module GlobalPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:operations_dashboard_available) do
        License.feature_available?(:operations_dashboard)
      end

      condition(:security_dashboard_available) do
        License.feature_available?(:security_dashboard)
      end

      rule { operations_dashboard_available }.enable :read_operations_dashboard
      rule { ~anonymous & security_dashboard_available }.enable :read_security_dashboard

      rule { admin }.policy do
        enable :read_licenses
        enable :destroy_licenses
      end

      rule { support_bot }.prevent :use_quick_actions

      rule { ~anonymous }.policy do
        enable :view_productivity_analytics
        enable :view_code_analytics
      end
    end
  end
end
