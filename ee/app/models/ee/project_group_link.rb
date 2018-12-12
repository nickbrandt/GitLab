# frozen_string_literal: true

module EE
  module ProjectGroupLink
    extend ActiveSupport::Concern

    prepended do
      before_destroy :delete_branch_protection
    end

    def delete_branch_protection
      if group.present? && project.present?
        project.protected_branches.merge_access_by_group(group).destroy_all # rubocop: disable DestroyAll
        project.protected_branches.push_access_by_group(group).destroy_all # rubocop: disable DestroyAll
      end
    end
  end
end
