# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::RefreshService do
  include ProjectForksHelper

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

  subject { service.execute(oldrev, newrev, "refs/heads/#{source_branch}") }

  describe '#execute' do
    context '#update_approvers' do
      let(:owner) { create(:user) }
      let(:current_user) { merge_request.author }
      let(:service) { described_class.new(project, current_user) }
      let(:enable_code_owner) { true }
      let(:todo_service) { double(:todo_service) }
      let(:notification_service) { double(:notification_service) }

      before do
        stub_licensed_features(code_owners: enable_code_owner)

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
end
