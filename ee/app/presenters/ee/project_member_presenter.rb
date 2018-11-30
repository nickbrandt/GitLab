module EE
  module ProjectMemberPresenter
    def group_sso?
      false
    end

    private

    def override_member_permission
      :override_project_member
    end
  end
end
