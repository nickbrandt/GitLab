# frozen_string_literal: true

module EE
  module ProjectMember
    extend ActiveSupport::Concern

    prepended do
      extend ::Gitlab::Utils::Override

      validate :sso_enforcement, if: :group

      before_destroy :delete_member_branch_protection
    end

    def group
      source&.group
    end

    def delete_member_branch_protection
      if user.present? && project.present?
        project.protected_branches.merge_access_by_user(user).destroy_all # rubocop: disable DestroyAll
        project.protected_branches.push_access_by_user(user).destroy_all # rubocop: disable DestroyAll
      end
    end
  end
end
