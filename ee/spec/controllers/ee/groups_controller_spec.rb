# frozen_string_literal: true

require 'spec_helper'

describe GroupsController do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:subgroup) { create(:group, :private, parent: group) }
  let_it_be(:subgroup2) { create(:group, :private, parent: subgroup) }

  describe 'GET #activity' do
    render_views

    let_it_be(:event1) { create(:event, project: project) }
    let_it_be(:event2) { create(:event, :epic_create_event, group: group) }
    let_it_be(:event3) { create(:event, :epic_create_event, group: subgroup) }
    let_it_be(:event4) { create(:event, :epic_create_event, group: subgroup2) }

    context 'when authorized' do
      before do
        group.add_owner(user)
        subgroup.add_owner(user)
        subgroup2.add_owner(user)
        sign_in(user)
      end

      context 'when group events are available' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'includes events from group and subgroups' do
          get :activity, params: { id: group.to_param }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq(4)
        end
      end

      context 'when group events are not available' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not include events from group and subgroups' do
          get :activity, params: { id: group.to_param }, format: :json

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['count']).to eq(1)
        end
      end
    end

    context 'when unauthorized' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'includes only events visible to user' do
        get :activity, params: { id: group.to_param }, format: :json

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['count']).to eq(2)
      end
    end
  end

  describe 'POST #restore' do
    let(:group) do
      create(:group_with_deletion_schedule,
        marked_for_deletion_on: 1.day.ago,
        deleting_user: user)
    end

    subject { post :restore, params: { group_id: group.to_param } }

    before do
      group.add_owner(user)
    end

    context 'when authenticated user can admin the group' do
      before do
        sign_in(user)
      end

      context 'adjourned deletion feature is available' do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
        end

        context 'success' do
          it 'restores the group' do
            expect { subject }.to change { group.reload.marked_for_deletion? }.from(true).to(false)
          end

          it 'renders success notice upon restoring' do
            subject

            expect(response).to redirect_to(edit_group_path(group))
            expect(flash[:notice]).to include "Group '#{group.name}' has been successfully restored."
          end
        end

        context 'failure' do
          before do
            allow(::Groups::RestoreService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: 'error' })
          end

          it 'does not restore the group' do
            expect { subject }.not_to change { group.reload.marked_for_deletion? }.from(true)
          end

          it 'redirects to group edit page' do
            subject

            expect(response).to redirect_to(edit_group_path(group))
            expect(flash[:alert]).to include 'error'
          end
        end
      end

      context 'adjourned deletion feature is not available' do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when authenticated user cannot admin the group' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: { id: group.to_param } }

    before do
      group.add_owner(user)
    end

    context 'when authenticated user can admin the group' do
      before do
        sign_in(user)
      end

      context 'adjourned deletion feature is available' do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
        end

        context 'success' do
          it 'marks the group for adjourned deletion' do
            expect { subject }.to change { group.reload.marked_for_deletion? }.from(false).to(true)
          end

          it 'does not immediately delete the group' do
            Sidekiq::Testing.fake! do
              expect { subject }.not_to change(GroupDestroyWorker.jobs, :size)
            end
          end

          it 'redirects to group path with notice about adjourned deletion' do
            subject

            expect(response).to redirect_to(group_path(group))
            expect(flash[:notice]).to include "'#{group.name}' has been scheduled for removal on"
          end
        end

        context 'failure' do
          before do
            allow(::Groups::MarkForDeletionService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: 'error' })
          end

          it 'does not mark the group for deletion' do
            expect { subject }.not_to change { group.reload.marked_for_deletion? }.from(false)
          end

          it 'redirects to group edit page' do
            subject

            expect(response).to redirect_to(edit_group_path(group))
            expect(flash[:alert]).to include 'error'
          end
        end
      end

      context 'adjourned deletion feature is not available' do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
        end

        it 'immediately schedules a group destroy' do
          Sidekiq::Testing.fake! do
            expect { subject }.to change(GroupDestroyWorker.jobs, :size).by(1)
          end
        end

        it 'redirects to root page with alert about immediate deletion' do
          subject

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include "Group '#{group.name}' was scheduled for deletion."
        end
      end
    end

    context 'when authenticated user cannot admin the group' do
      before do
        sign_in(create(:user))
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
