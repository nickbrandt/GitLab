# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectMilestones do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace ) }
  let_it_be(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones" do
    let_it_be(:route) { "/projects/#{project.id}/milestones" }
  end

  describe 'GET /projects/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let_it_be(:parent_group) { create(:group, :private) }
      let_it_be(:subgroup) { create(:group, :private, parent: parent_group) }
      let_it_be(:sub_project) { create(:project, group: subgroup) }
      let_it_be(:sub_project_milestone) { create(:milestone, project: sub_project) }
      let_it_be(:parent_group_milestone) { create(:milestone, group: parent_group) }
      let_it_be(:subgroup_milestone) { create(:milestone, group: subgroup) }
      let_it_be(:route) { "/projects/#{sub_project.id}/milestones" }
      let_it_be(:params) { { include_parent_milestones: true } }

      before do
        sub_project.add_developer(user)
      end

      shared_examples 'lists all milestones' do
        it 'includes parent and ancestors milestones' do
          milestones = [subgroup_milestone, parent_group_milestone, sub_project_milestone]

          get api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(3)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when user has access to all groups' do
        before do
          parent_group.add_developer(user)
          subgroup.add_developer(user)
        end

        it_behaves_like 'lists all milestones'

        context 'when iids param is present' do
          before do
            params.merge(iids: [sub_project_milestone.iid])
          end

          it_behaves_like 'lists all milestones'
        end
      end

      context 'when user has no access to an ancestor group' do
        let(:user2) { create(:user) }

        before do
          sub_project.add_developer(user2)
        end

        it 'does not show ancestor group milestones' do
          milestones = [subgroup_milestone, sub_project_milestone]

          get api(route, user2), params: { include_parent_milestones: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(2)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end
    end
  end

  describe 'DELETE /projects/:id/milestones/:milestone_id' do
    let(:guest) { create(:user) }
    let(:reporter) { create(:user) }

    before do
      project.add_reporter(reporter)
    end

    it 'returns 404 response when the project does not exist' do
      delete api("/projects/0/milestones/#{milestone.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 response when the milestone does not exist' do
      delete api("/projects/#{project.id}/milestones/0", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 from guest user deleting a milestone" do
      delete api("/projects/#{project.id}/milestones/#{milestone.id}", guest)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to test observer on close' do
    it 'creates an activity event when a milestone is closed' do
      path = "/projects/#{project.id}/milestones/#{milestone.id}"

      expect do
        put api(path, user), params: { state_event: 'close' }
      end.to change(Event, :count).by(1)
    end
  end

  describe 'POST /projects/:id/milestones/:milestone_id/promote' do
    let(:group) { create(:group) }

    before do
      project.update(namespace: group)
    end

    context 'when user does not have permission to promote milestone' do
      before do
        group.add_guest(user)
      end

      it 'returns 403' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user has permission' do
      before do
        group.add_developer(user)
      end

      it 'returns 200' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(group.milestones.first.title).to eq(milestone.title)
      end

      it 'returns 200 for closed milestone' do
        post api("/projects/#{project.id}/milestones/#{closed_milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(group.milestones.first.title).to eq(closed_milestone.title)
      end
    end

    context 'when no such resource' do
      before do
        group.add_developer(user)
      end

      it 'returns 404 response when the project does not exist' do
        post api("/projects/0/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 response when the milestone does not exist' do
        post api("/projects/#{project.id}/milestones/0/promote", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when project does not belong to group' do
      before do
        project.update(namespace: user.namespace)
      end

      it 'returns 403' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
