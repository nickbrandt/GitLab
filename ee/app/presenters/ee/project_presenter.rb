# frozen_string_literal: true

module EE
  module ProjectPresenter
    def approver_groups
      ::ApproverGroup.filtered_approver_groups(project.approver_groups, current_user)
    end
  end
end
