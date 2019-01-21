require 'spec_helper'

describe API::MergeRequestApprovals do
  set(:user)          { create(:user) }
  set(:user2)         { create(:user) }
  set(:admin)         { create(:user, :admin) }
  set(:project)       { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  set(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: Time.now) }

  before do
    project.update_attribute(:approvals_before_merge, 2)

    stub_feature_flags(approval_rules: false)
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    it 'retrieves the approval status' do
      approver = create :user
      group = create :group
      project.add_developer(approver)
      project.add_developer(create(:user))
      merge_request.approvals.create(user: approver)
      merge_request.approvers.create(user: approver)
      merge_request.approver_groups.create(group: group)

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 1
      expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
      expect(json_response['user_can_approve']).to be false
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
    end

    context 'when private group approver' do
      before do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)
      end

      it 'only shows group approvers visible to the user' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approver_groups']).to be_empty
      end

      context 'when admin' do
        it 'shows all approver groups' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", admin)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approver_groups'].size).to eq(1)
        end
      end
    end

    context 'when approvers are set to zero' do
      before do
        project.update!(approvals_before_merge: 0)
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)
      end

      it 'returns a 200' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'does not include an error in the response' do
        expect(json_response['message']).to eq(nil)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approvals' do
    shared_examples_for 'user allowed to override approvals required' do
      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
        end

        it 'allows you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), params: { approvals_required: 5 }
          end.to change { merge_request.reload.approvals_before_merge }.from(nil).to(5)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_required']).to eq(5)
        end

        context 'when project approvals are zero' do
          before do
            project.update!(approvals_before_merge: 0)
          end

          it 'does not include an error in the response' do
            expect do
              post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), params: { approvals_required: 0 }
            end.to change {merge_request.reload.approvals_before_merge}.from(nil).to(0)
            expect(json_response['message']).to eq(nil)
          end
        end

        it 'does not allow approvals required under what the project requires' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), params: { approvals_required: 1 }
          end.not_to change { merge_request.reload.approvals_before_merge }

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, true)
        end

        it 'does not allow you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), params: { approvals_required: 5 }
          end.not_to change { merge_request.reload.approvals_before_merge }

          expect(response).to have_gitlab_http_status(422)
        end
      end

      it 'only shows approver groups that are visible to current user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), params: { approvals_required: 5 }

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups'].size).to eq(approver_groups_count)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { user }
        let(:approver_groups_count) { 0 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { admin }
        let(:approver_groups_count) { 1 }
      end
    end

    context 'as a random user' do
      before do
        project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
      end

      it 'does not allow you to override approvals required' do
        expect do
          post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user2), params: { approvals_required: 5 }
        end.not_to change { merge_request.reload.approvals_before_merge }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'PUT :id/merge_requests/:merge_request_iid/approvers' do
    set(:approver) { create(:user) }
    set(:approver_group) { create(:group) }

    RSpec::Matchers.define_negated_matcher :not_change, :change

    shared_examples_for 'user allowed to change approvers' do
      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, true)
        end

        it 'does not allow overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              params: { approver_ids: [approver.id], approver_group_ids: [approver_group.id] }
          end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
        end

        it 'allows overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              params: { approver_ids: [approver.id], approver_group_ids: [approver_group.id] }
          end.to change { merge_request.approvers.count }.from(0).to(1)
             .and change { merge_request.approver_groups.count }.from(0).to(1)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
          expect(json_response['approver_groups'][0]['group']['name']).to eq(approver_group.name)
        end

        it 'removes approvers not in the payload' do
          merge_request.approvers.create(user: approver)
          merge_request.approver_groups.create(group: approver_group)

          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              params: { approver_ids: [], approver_group_ids: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
          end.to change { merge_request.approvers.count }.from(1).to(0)
             .and change { merge_request.approver_groups.count }.from(1).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers']).to eq([])
        end

        context 'when sending form-encoded data' do
          it 'removes approvers not in the payload' do
            merge_request.approvers.create(user: approver)
            merge_request.approver_groups.create(group: approver_group)

            expect do
              put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
                params: { approver_ids: '', approver_group_ids: '' }
            end.to change { merge_request.approvers.count }.from(1).to(0)
              .and change { merge_request.approver_groups.count }.from(1).to(0)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['approvers']).to eq([])
          end
        end
      end

      it 'only shows approver groups that are visible to current user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
          params: { approver_ids: [approver.id], approver_group_ids: [private_group.id, approver_group.id] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approver_groups'].size).to eq(approver_groups_count)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { user }
        let(:approver_groups_count) { 1 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { admin }
        let(:approver_groups_count) { 2 }
      end
    end

    context 'as a random user' do
      before do
        project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
      end

      it 'does not allow overriding approvers' do
        expect do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", user2),
            params: { approver_ids: [approver.id], approver_group_ids: [approver_group.id] }
        end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approve' do
    context 'as the author of the merge request' do
      before do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", user)
      end

      it 'returns a 401' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'as a valid approver' do
      set(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))
      end

      def approve(extra_params = {})
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", approver), params: extra_params
      end

      context 'when the sha param is not set' do
        before do
          approve
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
        end
      end

      context 'when the sha param is correct' do
        before do
          approve(sha: merge_request.diff_head_sha)
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
        end
      end

      context 'when the sha param is incorrect' do
        before do
          approve(sha: merge_request.diff_head_sha.reverse)
        end

        it 'returns a 409' do
          expect(response).to have_gitlab_http_status(409)
        end

        it 'does not approve the merge request' do
          expect(merge_request.reload.approvals_left).to eq(2)
        end
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        approve

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups']).to be_empty
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unapprove' do
    context 'as a user who has approved the merge request' do
      set(:approver) { create(:user) }
      set(:unapprover) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))
        merge_request.approvals.create(user: approver)
        merge_request.approvals.create(user: unapprover)
      end

      it 'unapproves the merge request' do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approvals_left']).to eq(1)
        usernames = json_response['approved_by'].map { |u| u['user']['username'] }
        expect(usernames).not_to include(unapprover.username)
        expect(usernames.size).to be 1
        expect(json_response['user_has_approved']).to be false
        expect(json_response['user_can_approve']).to be true
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups']).to be_empty
      end
    end
  end
end

describe "API::MergeRequestApprovals with approval_rule enabled" do
  set(:user)          { create(:user) }
  set(:user2)         { create(:user) }
  set(:admin)         { create(:user, :admin) }
  set(:project)       { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  set(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: Time.now) }

  set(:approver) { create :user }
  set(:group) { create :group }

  before do
    stub_feature_flags(approval_rule: true)
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }

    it 'retrieves the approval status' do
      project.add_developer(approver)
      project.add_developer(create(:user))
      merge_request.approvals.create(user: approver)
      rule.users << approver
      rule.groups << group

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 1
      expect(json_response['approval_rules_left']).to be_empty
      expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
      expect(json_response['user_can_approve']).to be false
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
      expect(json_response['approved']).to be true
    end

    it 'lists unapproved rule names' do
      project.add_developer(approver)
      project.add_developer(create(:user))
      rule.users << approver
      rule.groups << group

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", approver)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 2
      expect(json_response['approval_rules_left']).to eq(['foo'])
      expect(json_response['approved_by']).to be_empty
      expect(json_response['user_can_approve']).to be true
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
      expect(json_response['approved']).to be false
    end

    context 'when private group approver' do
      before do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)
      end

      it 'hides private group' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approver_groups'].size).to eq(0)
      end

      context 'when admin' do
        it 'shows all approver groups' do
          get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", admin)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approver_groups'].size).to eq(1)
        end
      end
    end

    context 'when approvers are set to zero' do
      before do
        create(:approval_project_rule, project: project, approvals_required: 0)
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)
      end

      it 'returns a 200' do
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approved']).to be true
        expect(json_response['message']).to eq(nil)
      end
    end
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approval_settings' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }

    it 'retrieves the approval rules details' do
      project.add_developer(approver)
      merge_request.approvals.create(user: approver)
      rule.users << approver

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_settings", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['rules'].size).to eq(1)

      rule_response = json_response['rules'].first

      expect(rule_response['id']).to eq(rule.id)
      expect(rule_response['name']).to eq('foo')
      expect(rule_response['approvers'][0]['username']).to eq(approver.username)
      expect(rule_response['approved_by'][0]['username']).to eq(approver.username)
    end

    it 'excludes private groups' do
      private_group = create :group, :private
      rule.groups << private_group

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_settings", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['rules'].size).to eq(1)

      rule_response = json_response['rules'].first

      expect(rule_response['id']).to eq(rule.id)
      expect(rule_response['groups'].size).to eq(0)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approvals' do
    shared_examples_for 'user allowed to override approvals required' do
      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update(disable_overriding_approvers_per_merge_request: false)
          create(:approval_merge_request_rule, merge_request: merge_request)
        end

        it 'allows you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5
          end.to change { merge_request.reload.approvals_before_merge }.from(nil).to(5)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_required']).to eq(5)
        end

        context 'when project approvals are zero' do
          before do
            project.update!(approvals_before_merge: 0)
          end

          it 'does not include an error in the response' do
            expect do
              post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 0
            end.to change {merge_request.reload.approvals_before_merge}.from(nil).to(0)
            expect(json_response['message']).to eq(nil)
          end
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not allow you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5
          end.not_to change { merge_request.reload.approvals_before_merge }

          expect(response).to have_gitlab_http_status(422)
        end
      end

      it 'only shows approver groups that are visible to current user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups'].size).to eq(expected_approver_group_size)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { user }
        let(:expected_approver_group_size) { 0 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { admin }
        let(:expected_approver_group_size) { 1 }
      end
    end

    context 'as a random user' do
      before do
        project.update(disable_overriding_approvers_per_merge_request: false)
      end

      it 'does not allow you to override approvals required' do
        expect do
          post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user2), approvals_required: 5
        end.not_to change { merge_request.reload.approvals_before_merge }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'PUT :id/merge_requests/:merge_request_iid/approvers' do
    RSpec::Matchers.define_negated_matcher :not_change, :change

    shared_examples_for 'user allowed to change approvers' do
      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not allow overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              approver_ids: [approver.id], approver_group_ids: [group.id]
          end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update(disable_overriding_approvers_per_merge_request: false)
        end

        it 'allows overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              approver_ids: [approver.id], approver_group_ids: [group.id]
          end.to change { merge_request.approvers.count }.from(0).to(1)
            .and change { merge_request.approver_groups.count }.from(0).to(1)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
          expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
        end

        it 'removes approvers not in the payload' do
          merge_request.approvers.create(user: approver)
          merge_request.approver_groups.create(group: group)

          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              { approver_ids: [], approver_group_ids: [] }.to_json, { CONTENT_TYPE: 'application/json' }
          end.to change { merge_request.approvers.count }.from(1).to(0)
            .and change { merge_request.approver_groups.count }.from(1).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers']).to eq([])
        end

        context 'when sending form-encoded data' do
          it 'removes approvers not in the payload' do
            merge_request.approvers.create(user: approver)
            merge_request.approver_groups.create(group: group)

            expect do
              put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
                approver_ids: '', approver_group_ids: ''
            end.to change { merge_request.approvers.count }.from(1).to(0)
              .and change { merge_request.approver_groups.count }.from(1).to(0)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['approvers']).to eq([])
          end
        end
      end

      it 'only shows approver groups that are visible to current user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
          approver_ids: [approver.id], approver_group_ids: [private_group.id, group.id]

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approver_groups'].size).to eq(expected_group_size)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { user }
        let(:expected_group_size) { 1 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { admin }
        let(:expected_group_size) { 2 }
      end
    end

    context 'as a random user' do
      before do
        project.update(disable_overriding_approvers_per_merge_request: false)
      end

      it 'does not allow overriding approvers' do
        expect do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", user2),
            approver_ids: [approver.id], approver_group_ids: [group.id]
        end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approve' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2) }

    context 'as the author of the merge request' do
      before do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", user)
      end

      it 'returns a 401' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'as a valid approver' do
      set(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))
        rule.users << approver
      end

      def approve(extra_params = {})
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", approver), extra_params
      end

      context 'when the sha param is not set' do
        before do
          approve
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
          expect(json_response['approved']).to be true
        end
      end

      context 'when the sha param is correct' do
        before do
          approve(sha: merge_request.diff_head_sha)
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
          expect(json_response['approved']).to be true
        end
      end

      context 'when the sha param is incorrect' do
        before do
          approve(sha: merge_request.diff_head_sha.reverse)
        end

        it 'returns a 409' do
          expect(response).to have_gitlab_http_status(409)
        end

        it 'does not approve the merge request' do
          expect(merge_request.reload.approval_state.approvals_left).to eq(2)
        end
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        approve

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups'].size).to eq(0)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unapprove' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }

    context 'as a user who has approved the merge request' do
      set(:approver) { create(:user) }
      set(:unapprover) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))
        merge_request.approvals.create(user: approver)
        merge_request.approvals.create(user: unapprover)
        rule.users = [approver, unapprover]
      end

      it 'unapproves the merge request' do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approvals_left']).to eq(1)
        usernames = json_response['approved_by'].map { |u| u['user']['username'] }
        expect(usernames).not_to include(unapprover.username)
        expect(usernames.size).to be 1
        expect(json_response['user_has_approved']).to be false
        expect(json_response['user_can_approve']).to be true
        expect(json_response['user_can_approve']).to be true
        expect(json_response['approved']).to be false
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create(group: private_group)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approver_groups'].size).to eq(0)
      end
    end
  end
end
