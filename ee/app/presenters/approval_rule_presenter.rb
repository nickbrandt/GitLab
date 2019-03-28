# frozen_string_literal: true

class ApprovalRulePresenter < Gitlab::View::Presenter::Delegated
  def groups
    group_query_service.visible_groups
  end

  def contains_hidden_groups?
    group_query_service.contains_hidden_groups?
  end

  private

  def group_query_service
    @group_query_service ||= ApprovalRules::GroupFinder.new(@subject, current_user)
  end
end
