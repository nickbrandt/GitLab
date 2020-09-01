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

    private

    def override_member_permission
      raise NotImplementedError
    end

    def source_allows_minimal_access_role?(member)
      member.source.minimal_access_role_allowed?
    end
  end
end
