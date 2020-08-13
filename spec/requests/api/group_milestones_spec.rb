# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupMilestones do
  let(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let(:project) { create(:project, namespace: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:closed_milestone) { create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, group: group, title: 'version2', description: 'open milestone') }

  it_behaves_like 'group and project milestones', "/groups/:id/milestones" do
    let(:route) { "/groups/#{group.id}/milestones" }
    let_it_be(:parent) { group }
    let_it_be(:subgroup) { create(:group, :private, parent: group) }
    let_it_be(:sub_parent) { subgroup }
    let_it_be(:sub_milestone) { create(:milestone, group: subgroup) }
  end

  def setup_for_group
    context_group.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    context_group.add_developer(user)
    public_project.update(namespace: context_group)
    context_group.reload
    # context_subgroup.add_developer(user)
  end
end
