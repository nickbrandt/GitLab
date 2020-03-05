# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class GmaMembershipEnforcer
        def initialize(project)
          @project = project
        end

        def can_add_user?(user)
          return true unless root_group&.enforced_group_managed_accounts?

          root_group == user.managing_group
        end

        private

        def root_group
          @root_group ||= @project.root_ancestor
        end
      end
    end
  end
end
