# frozen_string_literal: true
class GroupsWithTemplatesFinder
  # We need to provide grace period for users who are now using group_project_template
  # feature in free groups.
  CUT_OFF_DATE = Date.parse('2019/05/22') + 3.months

  def initialize(group_id = nil)
    @group_id = group_id
  end

  def execute
    if ::Gitlab::CurrentSettings.should_check_namespace_plan? && Time.zone.now > CUT_OFF_DATE
      groups = extended_group_search
      simple_group_search(groups)
    else
      simple_group_search(Group.all)
    end
  end

  private

  attr_reader :group_id

  # Cleanup issue: https://gitlab.com/gitlab-org/gitlab/issues/35733
  def extended_group_search
    if ::Feature.enabled?(:optimized_groups_with_templates_finder)
      groups = Group.with_project_templates_optimized
      groups_with_plan = Gitlab::ObjectHierarchy
        .new(groups)
        .base_and_ancestors
        .with_feature_available_in_plan(:group_project_templates)

      Gitlab::ObjectHierarchy.new(groups_with_plan).base_and_descendants
    else
      groups = Group.with_feature_available_in_plan(:group_project_templates)
      Gitlab::ObjectHierarchy.new(groups).base_and_descendants
    end
  end

  def simple_group_search(groups)
    groups = group_id ? groups.find_by(id: group_id)&.self_and_ancestors : groups # rubocop: disable CodeReuse/ActiveRecord
    return Group.none unless groups

    if ::Feature.enabled?(:optimized_groups_with_templates_finder)
      groups.with_project_templates_optimized
    else
      groups.with_project_templates
    end
  end
end
