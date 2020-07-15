# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectMilestones do
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones" do
    let(:route) { "/projects/#{project.id}/milestones" }
  end

  describe 'GET /projects/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let(:group) { create(:group, :public) }
      let(:project) { create(:project, group: group) }
      let!(:group_milestone) { create(:milestone, group: group) }

      context 'when user has access to group parent' do
        let(:nested_group) { create(:group, :public, parent: group) }
        let!(:nested_group_milestone) { create(:milestone, group: nested_group) }

        it 'result includes parent group and subgroup milestones' do
          milestones = [nested_group_milestone, group_milestone, milestone, closed_milestone]

          get api("/projects/#{project.id}/milestones", user),
              params: { include_parent_milestones: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(4)

          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when user has no access to group parent' do
        it 'does not show parent group milestones' do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(false)

          get api("/projects/#{project.id}/milestones", user),
              params: { include_parent_milestones: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(2)
        end
      end

      context 'when filtering by iids' do
        it 'does not filer by iids' do
          milestones = [group_milestone, milestone, closed_milestone]

          get api("/projects/#{project.id}/milestones", user),
              params: { include_parent_milestones: true, iids: [group_milestone.iid] }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(3)

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
      expect(Event).to receive(:create!)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          params: { state_event: 'close' }
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
