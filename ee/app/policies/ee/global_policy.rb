# frozen_string_literal: true

module EE
  module GlobalPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:operations_dashboard_available) do
        License.feature_available?(:operations_dashboard)
      end

      rule { operations_dashboard_available }.enable :read_operations_dashboard
      rule { admin }.policy do
        enable :read_licenses
        enable :destroy_licenses
      end

      rule { support_bot }.prevent :use_quick_actions
    end
  end
end
