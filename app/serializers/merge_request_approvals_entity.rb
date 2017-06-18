class MergeRequestApprovalsEntity < Grape::Entity
  include RequestAwareEntity

  expose :approvals_required
  expose :approvals_left
  expose :approvals, as: :approved_by, using: ApproversEntity
  expose :approvers_left, as: :suggested_approvers, using: UserEntity

  expose :user_can_approve do |merge_request, options|
    merge_request.can_approve?(current_user)
  end

  expose :user_has_approved do |merge_request, options|
    merge_request.has_approved?(current_user)
  end

  delegate :current_user, to: :request
end
