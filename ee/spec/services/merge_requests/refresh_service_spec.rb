# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::RefreshService do
  include ProjectForksHelper

  let(:service) { described_class }

  describe '#execute' do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, :repository, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true)
      @fork_project = fork_project(@project, @user, repository: true)

      @merge_request = create(:merge_request,
                              source_project: @project,
                              source_branch: 'master',
                              target_branch: 'feature',
                              target_project: @project,
                              merge_when_pipeline_succeeds: true,
                              merge_user: @user)

      @fork_merge_request = create(:merge_request,
                                   source_project: @fork_project,
                                   source_branch: 'master',
                                   target_branch: 'feature',
                                   target_project: @project)

      @merge_request.approvals.create(user_id: @user.id)
      @fork_merge_request.approvals.create(user_id: @user.id)

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(@project, @user) }
      let(:notification_service) { spy('notification_service') }

      before do
        allow(refresh_service).to receive(:execute_hooks)
        allow(NotificationService).to receive(:new) { notification_service }
      end

      it 'resets approvals' do
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.approvals).to be_empty
        expect(@fork_merge_request.approvals).not_to be_empty
      end
    end

    context 'push to origin repo target branch' do
      context 'when all MRs to the target branch had diffs' do
        before do
          service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
          expect(@fork_merge_request.approvals).not_to be_empty
        end
      end
    end

    context 'push to fork repo source branch' do
      let(:refresh_service) { service.new(@fork_project, @user) }

      def refresh
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      context 'open fork merge request' do
        it 'resets approvals', :sidekiq_might_not_need_inline do
          refresh

          expect(@merge_request.approvals).not_to be_empty
          expect(@fork_merge_request.approvals).to be_empty
        end
      end

      context 'closed fork merge request' do
        before do
          @fork_merge_request.close!
        end

        it 'resets approvals', :sidekiq_might_not_need_inline do
          refresh

          expect(@merge_request.approvals).not_to be_empty
          expect(@fork_merge_request.approvals).to be_empty
        end
      end
    end

    context 'push to fork repo target branch' do
      describe 'changes to merge requests' do
        before do
          service.new(@fork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
        end

        it 'does not reset approvals', :sidekiq_might_not_need_inline do
          expect(@merge_request.approvals).not_to be_empty
          expect(@fork_merge_request.approvals).not_to be_empty
        end
      end
    end

    context 'push to origin repo target branch after fork project was removed' do
      before do
        @fork_project.destroy
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it 'does not reset approvals' do
        expect(@merge_request.approvals).not_to be_empty
        expect(@fork_merge_request.approvals).not_to be_empty
      end
    end

    context 'resetting approvals if they are enabled' do
      context 'when approvals_before_merge is disabled' do
        before do
          @project.update(approvals_before_merge: 0)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'resets approvals' do
          expect(@merge_request.approvals).to be_empty
        end
      end

      context 'when reset_approvals_on_push is disabled' do
        before do
          @project.update(reset_approvals_on_push: false)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
        end
      end

      context 'when the rebase_commit_sha on the MR matches the pushed SHA' do
        before do
          @merge_request.update(rebase_commit_sha: @newrev)
          refresh_service = service.new(@project, @user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(@merge_request.approvals).not_to be_empty
        end
      end

      context 'when there are approvals' do
        context 'closed merge request' do
          before do
            @merge_request.close!
            refresh_service = service.new(@project, @user)
            allow(refresh_service).to receive(:execute_hooks)
            refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
            reload_mrs
          end

          it 'resets the approvals' do
            expect(@merge_request.approvals).to be_empty
          end
        end

        context 'opened merge request' do
          before do
            refresh_service = service.new(@project, @user)
            allow(refresh_service).to receive(:execute_hooks)
            refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
            reload_mrs
          end

          it 'resets the approvals' do
            expect(@merge_request.approvals).to be_empty
          end
        end
      end
    end

    def reload_mrs
      @merge_request.reload
      @fork_merge_request.reload
    end
  end
end
