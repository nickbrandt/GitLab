# frozen_string_literal: true

class ApprovalRulePresenter < Gitlab::View::Presenter::Delegated
  def groups
    super.public_or_visible_to_user(current_user)
  end
end
