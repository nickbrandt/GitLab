# frozen_string_literal: true

require 'spec_helper'

shared_examples 'approvals' do
  let!(:approver) { create(:user) }
  let!(:approval_rule) { create(:approval_project_rule, project: project, users: [approver, user], approvals_required: 2) }

  before do
    project.add_developer(approver)
  end

  describe 'approve' do
    before do
      post :approve,
           params: {
             namespace_id: project.namespace.to_param,
             project_id: project.to_param,
             id: merge_request.iid
           },
           format: :json
    end

    it 'approves the merge request' do
      approvals = json_response

      expect(response).to be_successful
      expect(approvals['approvals_left']).to eq 1
      expect(approvals['approved_by'].size).to eq 1
      expect(approvals['approved_by'][0]['user']['username']).to eq user.username
      expect(approvals['user_has_approved']).to be true
      expect(approvals['user_can_approve']).to be false
      expect(approvals['suggested_approvers'].size).to eq 1
      expect(approvals['suggested_approvers'][0]['username']).to eq approver.username
    end
  end

  describe 'approvals' do
    let!(:approval) { create(:approval, merge_request: merge_request, user: approver) }

    def get_approvals
      get :approvals,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: merge_request.iid
          },
          format: :json
    end

    it 'shows approval information' do
      get_approvals

      approvals = json_response

      expect(response).to be_successful
      expect(approvals['approvals_left']).to eq 1
      expect(approvals['approved_by'].size).to eq 1
      expect(approvals['approved_by'][0]['user']['username']).to eq approver.username
      expect(approvals['user_has_approved']).to be false
      expect(approvals['user_can_approve']).to be true
      expect(approvals['suggested_approvers'].size).to eq 1
      expect(approvals['suggested_approvers'][0]['username']).to eq user.username
    end
  end

  describe 'unapprove' do
    let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

    before do
      delete :unapprove,
             params: {
               namespace_id: project.namespace.to_param,
               project_id: project.to_param,
               id: merge_request.iid
             },
             format: :json
    end

    it 'unapproves the merge request' do
      approvals = json_response

      expect(response).to be_successful
      expect(approvals['approvals_left']).to eq 2
      expect(approvals['approved_by']).to be_empty
      expect(approvals['user_has_approved']).to be false
      expect(approvals['user_can_approve']).to be true
      expect(approvals['suggested_approvers'].size).to eq 2
    end
  end
end

describe Projects::MergeRequestsController do
  include ProjectForksHelper

  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: create(:user)) }
  let(:user)          { project.creator }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  it_behaves_like 'approvals'

  describe 'PUT update' do
    before do
      project.update(approvals_before_merge: 2)
    end

    def update_merge_request(params = {})
      post :update,
           params: {
             namespace_id: merge_request.target_project.namespace.to_param,
             project_id: merge_request.target_project.to_param,
             id: merge_request.iid,
             merge_request: params
           }
    end

    context 'when the merge request requires approval' do
      before do
        project.update(approvals_before_merge: 1)
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end

    context 'overriding approvers per MR' do
      before do
        project.update(approvals_before_merge: 1)
      end

      context 'enabled' do
        before do
          project.update(disable_overriding_approvers_per_merge_request: false)
        end

        it 'updates approvals' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(2)
        end

        it 'does not allow approvels before merge lower than the project setting' do
          update_merge_request(approvals_before_merge: 0)

          expect(merge_request.reload.approvals_before_merge).to eq(1)
        end

        it 'creates rules' do
          users = create_list(:user, 3)
          users.each { |user| project.add_developer(user) }

          update_merge_request(approval_rules_attributes: [
            { name: 'foo', user_ids: users.map(&:id), approvals_required: 3 }
          ])

          expect(merge_request.reload.approval_rules.size).to eq(1)

          rule = merge_request.reload.approval_rules.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(3)
        end
      end

      context 'disabled' do
        let(:new_approver) { create(:user) }
        let(:new_approver_group) { create(:approver_group) }

        before do
          project.add_developer(new_approver)
          project.update(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not update approvals_before_merge' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'does not update approver_ids' do
          update_merge_request(approver_ids: [new_approver].map(&:id).join(','))

          expect(merge_request.reload.approver_ids).to be_empty
        end

        it 'does not update approver_group_ids' do
          update_merge_request(approver_group_ids: [new_approver_group].map(&:id).join(','))

          expect(merge_request.reload.approver_group_ids).to be_empty
        end

        it 'does not create approval rules' do
          update_merge_request(
            approval_rules_attributes: [
              {
                name: 'Test',
                user_ids: [new_approver.id],
                approvals_required: 1
              }
            ]
          )

          expect(merge_request.reload.approval_rules).to be_empty
        end
      end
    end

    shared_examples 'approvals_before_merge param' do
      before do
        project.update(approvals_before_merge: 2)
      end

      context 'approvals_before_merge not set for the existing MR' do
        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the sames as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end

      context 'approvals_before_merge set for the existing MR' do
        before do
          merge_request.update_attribute(:approvals_before_merge, 4)
        end

        context 'when it is not set' do
          before do
            update_merge_request(title: 'New title')
          end

          it 'does not change the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(4)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end
    end

    context 'when the MR targets the project' do
      it_behaves_like 'approvals_before_merge param'
    end

    context 'when the project is a fork' do
      let(:upstream) { create(:project, :repository) }
      let(:project) { fork_project(upstream, nil, repository: true) }

      context 'when the MR target upstream' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting upstream', source_project: project, target_project: upstream) }

        before do
          upstream.add_developer(user)
          upstream.update(approvals_before_merge: 2)
        end

        it_behaves_like 'approvals_before_merge param'
      end

      context 'when the MR target the fork' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting the fork', source_project: project, target_project: project) }

        before do
          project.add_developer(user)
          project.update(approvals_before_merge: 0)
        end

        it_behaves_like 'approvals_before_merge param'
      end
    end
  end

  describe 'POST #rebase' do
    def post_rebase
      post :rebase, params: { namespace_id: project.namespace, project_id: project, id: merge_request }
    end

    def expect_rebase_worker_for(user)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id)
    end

    context 'approvals pending' do
      let(:project) { create(:project, :repository, approvals_before_merge: 1) }

      it 'returns 200' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response.status).to eq(200)
      end
    end

    context 'with a forked project' do
      let(:forked_project) { fork_project(project, fork_owner, repository: true) }
      let(:fork_owner) { create(:user) }

      before do
        project.add_developer(fork_owner)
        merge_request.update!(source_project: forked_project)
        forked_project.add_reporter(user)
      end

      it_behaves_like 'approvals'
    end
  end

  describe 'GET #dependency_scanning_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dependency_scanning_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareDependencyScanningReportsService, project.users.first).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse container scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse container scanning reports' })
      end
    end

    context 'public project with private builds' do
      let(:comparison_status) { {} }
      let(:project) { create(:project, :public, :builds_private) }

      before do
        sign_out user
      end

      it 'restricts unauthorized access' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #container_scanning_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_container_scanning_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :container_scanning_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareContainerScanningReportsService, project.users.first).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse container scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse container scanning reports' })
      end
    end

    context 'public project with private builds' do
      let(:comparison_status) { {} }
      let(:project) { create(:project, :public, :builds_private) }

      before do
        sign_out user
      end

      it 'restricts unauthorized access' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #sast_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_sast_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :sast_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSastReportsService, project.users.first).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse sast reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse sast reports' })
      end
    end

    context 'public project with private builds' do
      let(:comparison_status) { {} }
      let(:project) { create(:project, :public, :builds_private) }

      before do
        sign_out user
      end

      it 'restricts unauthorized access' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #dast_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dast_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareDastReportsService, project.users.first).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse DAST reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse DAST reports' })
      end
    end

    context 'public project with private builds' do
      let(:comparison_status) { {} }
      let(:project) { create(:project, :public, :builds_private) }

      it 'restricts access to signed out users' do
        sign_out user

        subject

        expect(response).to have_gitlab_http_status(404)
      end

      it 'restricts access to other users' do
        sign_in create(:user)

        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET #license_management_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_license_management_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :license_management_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareLicenseScanningReportsService, project.users.first).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "new_licenses" => [], "existing_licenses" => [], "removed_licenses" => [] })
      end
    end

    context 'when user created corrupted test reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse license scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse license scanning reports' })
      end
    end
  end

  describe 'GET #metrics_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_metrics_reports, source_project: project, author: create(:user)) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :metrics_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareMetricsReportsService).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { summary: 1 } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'summary' => 1 })
      end
    end

    context 'when user created corrupted test reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse test reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse test reports' })
      end
    end
  end

  it_behaves_like DescriptionDiffActions do
    let_it_be(:project)  { create(:project, :repository, :public) }
    let_it_be(:issuable) { create(:merge_request, source_project: project) }
  end
end
