# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData do
  describe '.uncached_data' do
    context 'when on Gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not include usage_activity_by_stage data' do
        expect(described_class.uncached_data).not_to include(:usage_activity_by_stage)
      end

      context 'when feature is enabled' do
        before do
          stub_feature_flags(usage_activity_by_stage: true)
        end

        it 'does not include usage_activity_by_stage data' do
          expect(described_class.uncached_data).not_to include(:usage_activity_by_stage)
        end
      end
    end

    context 'when the :usage_activity_by_stage feaure is not enabled' do
      before do
        stub_feature_flags(usage_activity_by_stage: false)
      end

      it 'does not include usage_activity_by_stage data' do
        expect(described_class.uncached_data).not_to include(:usage_activity_by_stage)
      end
    end

    context 'when not on Gitlab.com' do
      it 'includes usage_activity_by_stage data' do
        expect(described_class.uncached_data).to include(:usage_activity_by_stage)
      end

      context 'for Manage' do
        it 'includes accurate usage_activity_by_stage data' do
          user = create(:user)
          create(:group_member, user: user)
          create(:key, type: 'LDAPKey', user: user)
          create(:group_member, ldap: true, user: user)

          expect(described_class.uncached_data[:usage_activity_by_stage][:manage]).to eq(
            groups: 1,
            ldap_keys: 1,
            ldap_users: 1
          )
        end
      end

      context 'for Plan' do
        it 'includes accurate usage_activity_by_stage data' do
          stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)

          user    = create(:user)
          project = create(:project, creator: user)
          issue   = create(:issue, project: project, author: User.support_bot)
          board   = create(:board, project: project)
          create(:user_list, board: board, user: user)
          create(:milestone_list, board: board, milestone: create(:milestone, project: project), user: user)
          create(:list, board: board, label: create(:label, project: project), user: user)
          create(:note, project: project, noteable: issue, author: user)
          create(:epic, author: user)
          create(:todo, project: project, target: issue, author: user)
          create(:jira_service, :jira_cloud_service, active: true, project: create(:project, :jira_dvcs_cloud, creator: user))
          create(:jira_service, active: true, project: create(:project, :jira_dvcs_server, creator: user))

          expect(described_class.uncached_data[:usage_activity_by_stage][:plan]).to eq(
            assignee_lists: 1,
            epics: 1,
            issues: 1,
            label_lists: 1,
            milestone_lists: 1,
            notes: 1,
            projects: 1,
            projects_jira_active: 1,
            projects_jira_dvcs_cloud_active: 1,
            projects_jira_dvcs_server_active: 1,
            service_desk_enabled_projects: 1,
            service_desk_issues: 1,
            todos: 1
          )
        end
      end

      context 'for create' do
        it 'includes accurate usage_activity_by_stage data' do
          user = create(:user)
          project = create(:project, :repository_private, :requiring_code_owner_approval, :github_imported,
                           :test_repo, :remote_mirror, creator: user)
          create(:deploy_key, user: user)
          create(:key, user: user)
          create(:merge_request, source_project: project)
          create(:project, creator: user)
          create(:protected_branch, project: project)
          create(:remote_mirror, project: project)
          create(:snippet, author: user)
          create(:suggestion, note: create(:note, project: project))

          expect(described_class.uncached_data[:usage_activity_by_stage][:create]).to eq(
            deploy_keys: 1,
            keys: 1,
            merge_requests: 1,
            projects_enforcing_code_owner_approval: 1,
            projects_imported_from_github: 1,
            projects_with_repositories_enabled: 1,
            protected_branches: 1,
            remote_mirrors: 1,
            snippets: 1,
            suggestions: 1
          )
        end
      end
    end
  end
end
