module EE
  module GroupMemberPresenter
    def group_sso?
      member.user.group_sso?(source)
    end

    private

    def override_member_permission
      :override_group_member
    end
  end
end
