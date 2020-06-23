# frozen_string_literal: true

module EE
  module NamespacePolicy
    extend ActiveSupport::Concern

    prepended do
      rule { owner | admin }.policy do
        enable :create_jira_connect_subscription
      end

      rule { admin & is_gitlab_com }.enable :update_subscription_limit
    end
  end
end
