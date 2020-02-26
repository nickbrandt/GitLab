# frozen_string_literal: true

class GroupHook < ProjectHook
  include CustomModelNaming
  include TriggerableHooks

  self.singular_route_key = :hook

  triggerable_hooks [
    :push_hooks,
    :tag_push_hooks,
    :issue_hooks,
    :confidential_issue_hooks,
    :note_hooks,
    :merge_request_hooks,
    :job_hooks,
    :pipeline_hooks,
    :wiki_page_hooks
  ]

  belongs_to :group

  clear_validators!
  validates :url, presence: true, addressable_url: true
  validate :validate_group_hook_limits_not_exceeded, on: :create

  def pluralized_name
    _('Group Hooks')
  end

  private

  def validate_group_hook_limits_not_exceeded
    return unless group

    if group.actual_limits.exceeded?(:group_hooks, GroupHook.where(group: group))
      errors.add(:base, _("Maximum number of group hooks (%{count}) exceeded") %
        { count: group.actual_limits.group_hooks })
    end
  end
end
