# frozen_string_literal: true
class GroupsWithTemplatesFinder
  # We need to provide grace period for users who are now using group_project_template
  # feature in free groups.
  CUT_OFF_DATE = Date.parse('2019/05/22') + 3.months

  def initialize(group_id = nil)
    @group_id = group_id
  end

  def execute
    groups = @group_id ? ::Group.find(group_id).self_and_ancestors : ::Group.all
    groups = groups.with_project_templates

    if ::Gitlab::CurrentSettings.should_check_namespace_plan? && Time.zone.now > CUT_OFF_DATE
      groups = groups.with_feature_available_in_plan(:group_project_templates)
    end

    groups
  end

  private

  attr_reader :group_id
end
