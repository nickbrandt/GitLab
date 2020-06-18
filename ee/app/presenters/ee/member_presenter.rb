# frozen_string_literal: true

module EE
  module MemberPresenter
    extend ::Gitlab::Utils::Override

    def can_update?
      super || can_override?
    end

    override :can_override?
    def can_override?
      can?(current_user, override_member_permission, member)
    end

    override :valid_level_roles
    def valid_level_roles
      return super if member.source.is_a?(Project) || source_allows_unassigned_role?(member)

      super.except("Unassigned")
    end

    private

    def override_member_permission
      raise NotImplementedError
    end

    def source_allows_unassigned_role?(member)
      member.source.unassigned_role_allowed?
    end
  end
end
