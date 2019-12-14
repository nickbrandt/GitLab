# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::RefreshService do
  include ProjectForksHelper
  include ProjectHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true) }
  let(:forked_project) { fork_project(project, fork_user, repository: true) }

  let(:fork_user) { create(:user) }

  let(:source_branch) { 'between-create-delete-modify-move' }
  let(:merge_request) do
    create(:merge_request,
      source_project: project,
      source_branch: source_branch,
      target_branch: 'master',
      target_project: project)
  end
  let(:another_merge_request) do
    create(:merge_request,
      source_project: project,
      source_branch: source_branch,
      target_branch: 'test',
      target_project: project)
  end
  let(:forked_merge_request) do
    create(:merge_request,
      source_project: forked_project,
      source_branch: source_branch,
      target_branch: 'master',
      target_project: project)
  end
  let(:oldrev) { TestEnv::BRANCH_SHA[source_branch] }
  let(:newrev) { TestEnv::BRANCH_SHA['after-create-delete-modify-move'] } # Pretend source_branch is now updated
  let(:service) { described_class.new(project, current_user) }
  let(:current_user) { merge_request.author }

  subject { service.execute(oldrev, newrev, "refs/heads/#{source_branch}") }

  describe '#execute' do
    it 'checks merge train status' do
      expect_next_instance_of(MergeTrains::CheckStatusService, project, current_user) do |service|
        expect(service).to receive(:execute).with(project, source_branch, newrev)
      end

      subject
    end

    context '#update_approvers' do
      let(:owner) { create(:user) }
      let(:current_user) { merge_request.author }
      let(:service) { described_class.new(project, current_user) }
      let(:enable_code_owner) { true }
      let(:enable_report_approver_rules) { true }
      let(:todo_service) { double(:todo_service) }
      let(:notification_service) { double(:notification_service) }

      before do
        stub_licensed_features(code_owners: enable_code_owner)
        stub_licensed_features(report_approver_rules: enable_report_approver_rules)

        allow(service).to receive(:mark_pending_todos_done)
        allow(service).to receive(:notify_about_push)
        allow(service).to receive(:execute_hooks)
        allow(service).to receive(:todo_service).and_return(todo_service)
        allow(service).to receive(:notification_service).and_return(notification_service)

        group.add_master(fork_user)

        merge_request
        another_merge_request
        forked_merge_request
      end

      context 'when code owners disabled' do
        let(:enable_code_owner) { false }

        it 'does nothing' do
          expect(::Gitlab::CodeOwners).not_to receive(:for_merge_request)

          subject
        end
      end

      context 'when code owners enabled' do
        let(:relevant_merge_requests) { [merge_request, another_merge_request] }

        it 'refreshes the code owner rules for all relevant merge requests' do
          fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

          relevant_merge_requests.each do |merge_request|
            expect(::MergeRequests::SyncCodeOwnerApprovalRules)
              .to receive(:new).with(merge_request).and_return(fake_refresh_service)
            expect(fake_refresh_service).to receive(:execute)
          end

          subject
        end
      end

      context 'when report_approver_rules enabled, with approval_rule enabled' do
        let(:relevant_merge_requests) { [merge_request, another_merge_request] }

        it 'refreshes the report_approver rules for all relevant merge requests' do
          relevant_merge_requests.each do |merge_request|
            expect_next_instance_of(::MergeRequests::SyncReportApproverApprovalRules, merge_request) do |service|
              expect(service).to receive(:execute)
            end
          end

          subject
        end
      end
    end

    describe 'Pipelines for merge requests' do
      let(:service) { described_class.new(project, current_user) }
      let(:current_user) { merge_request.author }

      let(:config) do
        {
          test: {
            stage: 'test',
            script: 'echo',
            only: ['merge_requests']
          }
        }
      end

      before do
        project.add_developer(current_user)
        project.update(merge_pipelines_enabled: true)
        stub_licensed_features(merge_pipelines: true)
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      it 'creates a merge request pipeline' do
        expect { subject }
          .to change { merge_request.pipelines_for_merge_request.count }.by(1)

        expect(merge_request.all_pipelines.last).to be_merge_request_pipeline
      end

      context 'when MergeRequestUpdateWorker is retried by an exception' do
        it 'does not re-create a duplicate merge request pipeline' do
          expect do
            service.execute(oldrev, newrev, "refs/heads/#{source_branch}")
          end.to change { merge_request.pipelines_for_merge_request.count }.by(1)

          expect do
            service.execute(oldrev, newrev, "refs/heads/#{source_branch}")
          end.not_to change { merge_request.pipelines_for_merge_request.count }
        end
      end
    end
  end

  describe '#abort_ff_merge_requests_with_when_pipeline_succeeds' do
    let_it_be(:project) { create(:project, :repository, merge_method: 'ff') }
    let_it_be(:author) { create_user_from_membership(project, :developer) }
    let_it_be(:user) { create(:user) }

    let_it_be(:merge_request, refind: true) do
      create(:merge_request,
             author: author,
             source_project: project,
             source_branch: 'feature',
             target_branch: 'master',
             target_project: project,
             auto_merge_enabled: true,
             merge_user: user)
    end

    let_it_be(:newrev) do
      project
        .repository
        .create_file(user, 'test1.txt', 'Test data',
                     message: 'Test commit', branch_name: 'master')
    end

    let_it_be(:oldrev) do
      project
        .repository
        .commit(newrev)
        .parent_id
    end

    let(:refresh_service) { described_class.new(project, user) }

    before do
      merge_request.auto_merge_strategy = auto_merge_strategy
      merge_request.save!

      refresh_service.execute(oldrev, newrev, 'refs/heads/master')
      merge_request.reload
    end

    context 'with add to merge train when pipeline succeeds strategy' do
      let(:auto_merge_strategy) do
        AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS
      end

      it_behaves_like 'maintained merge requests for MWPS'
    end

    context 'with merge train strategy' do
      let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_TRAIN }

      it_behaves_like 'maintained merge requests for MWPS'
    end
  end
end
