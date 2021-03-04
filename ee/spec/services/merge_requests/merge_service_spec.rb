# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project, user, sha: merge_request.diff_head_sha, commit_message: 'Awesome message') }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'project has exceeded size limit' do
      before do
        allow(project.repository_size_checker).to receive(:above_size_limit?).and_return(true)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to include('This merge request cannot be merged')
      end
    end

    context 'when merge request rule exists' do
      let(:approver) { create(:user) }
      let!(:approval_rule) { create :approval_merge_request_rule, merge_request: merge_request, users: [approver] }
      let!(:approval) { create :approval, merge_request: merge_request, user: approver }

      it 'creates approved_approvers' do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
        merge_request.reload
        rule = merge_request.approval_rules.first

        expect(merge_request.merged?).to eq(true)
        expect(rule.approved_approvers).to contain_exactly(approver)
      end
    end

    context 'jira issue enforcement' do
      subject do
        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      shared_examples 'merges the MR with no error' do
        it do
          subject

          expect(merge_request.reload.merged?).to eq(true)
        end
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(jira_issue_association_enforcement: true)
          stub_feature_flags(jira_issue_association_on_merge_request: true)
        end

        context 'when jira issue is required for merge' do
          before do
            project.create_project_setting(prevent_merge_without_jira_issue: true)
          end

          context 'when issue key is NOT specified in MR title / description' do
            it 'returns appropriate merge error' do
              subject

              expect(merge_request.merge_error).to include('Before this can be merged, a Jira issue must be linked in the title or description')
            end
          end

          context 'when issue key is specified in MR title / description' do
            before do
              merge_request.update!(title: "Fixes login issue SECURITY-1234")
            end

            it_behaves_like 'merges the MR with no error'
          end
        end

        context 'when jira issue is NOT required for merge' do
          before do
            project.create_project_setting(prevent_merge_without_jira_issue: false)
          end

          it_behaves_like 'merges the MR with no error'
        end
      end

      context 'when feature is NOT available' do
        using RSpec::Parameterized::TableSyntax

        where(:licensed, :feature_flag) do
          false | true
          true  | false
          false | false
        end

        with_them do
          before do
            stub_licensed_features(jira_issue_association_enforcement: licensed)
            stub_feature_flags(jira_issue_association_on_merge_request: feature_flag)
          end

          it_behaves_like 'merges the MR with no error'
        end
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: true
end
