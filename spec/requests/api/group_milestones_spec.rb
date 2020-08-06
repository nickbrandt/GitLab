# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupMilestones do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:group_member) { create(:group_member, group: group, user: user) }
  let_it_be(:closed_milestone) { create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone') }
  let_it_be(:milestone) { create(:milestone, group: group, title: 'version2', description: 'open milestone') }

  it_behaves_like 'group and project milestones', "/groups/:id/milestones" do
    let(:route) { "/groups/#{group.id}/milestones" }
  end

  describe 'GET /groups/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let_it_be(:subgroup) { create(:group, :private, parent: group) }
      let_it_be(:subgroup_milestone) { create(:milestone, group: subgroup) }
      let_it_be(:route) { "/groups/#{subgroup.id}/milestones" }
      let_it_be(:params) { { include_parent_milestones: true } }

      shared_examples 'lists all milestones' do
        it 'includes parent and ancestors milestones' do
          milestones = [subgroup_milestone, milestone, closed_milestone]

          get api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(3)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when user has access to all groups' do
        before do
          group.add_developer(user)
          subgroup.add_developer(user)
        end

        it_behaves_like 'lists all milestones'

        context 'when iids param is present' do
          before do
            params.merge(iids: [milestone.iid])
          end

          it_behaves_like 'lists all milestones'
        end
      end

      context 'when user has no access to an ancestor group' do
        let_it_be(:user2) { create(:user) }

        before do
          subgroup.add_developer(user2)
        end

        it 'does not show ancestor group milestones' do
          milestones = [subgroup_milestone]

          get api(route, user2), params: { include_parent_milestones: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end
    end
  end

  def setup_for_group
    context_group.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    context_group.add_developer(user)
    public_project.update(namespace: context_group)
    context_group.reload
  end
end
