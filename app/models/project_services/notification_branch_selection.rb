# frozen_string_literal: true

# This module will be included in ChatNotificationService and
# PipelinesEmailService classes. Not to be used directly.
module NotificationBranchSelection
  BRANCH_CHOICES = [
    ['All branches', 'all'],
    ['Default branch', 'default'],
    ['Protected branches', 'protected'],
    ['Default branch and protected branches', 'default_and_protected']
  ].freeze

  def notify_for_branch?(data)
    ref = if data[:ref]
            Gitlab::Git.ref_name(data[:ref])
          else
            data.dig(:object_attributes, :ref)
          end

    is_default_branch = ref == project.default_branch
    is_protected_branch = project.protected_branches.exists?(name: ref)

    if branches_to_be_notified == "all"
      true
    elsif branches_to_be_notified == "default"
      is_default_branch
    elsif branches_to_be_notified == "protected"
      is_protected_branch
    elsif branches_to_be_notified == "default_and_protected"
      is_default_branch || is_protected_branch
    else
      false
    end
  end
end
