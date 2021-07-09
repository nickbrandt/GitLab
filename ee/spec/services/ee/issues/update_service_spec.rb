# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::UpdateService do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }
  let_it_be(:epic) { create(:epic, group: group) }

  let(:author) { issue.author }
  let(:user) { author }

  describe 'execute' do
    before do
      project.add_reporter(author)
    end

    def update_issue(opts)
      described_class.new(project: project, current_user: user, params: opts).execute(issue)
    end

    context 'refresh epic dates' do
      before do
        issue.update!(epic: epic)
      end

      context 'updating milestone' do
        let_it_be(:milestone) { create(:milestone, project: project) }

        it 'calls UpdateDatesService' do
          expect(Epics::UpdateDatesService).to receive(:new).with([epic]).and_call_original.twice

          update_issue(milestone: milestone)
          update_issue(milestone_id: nil)
        end
      end

      context 'updating iteration' do
        let_it_be(:iteration) { create(:iteration, group: group) }

        context 'when issue does not already have an iteration' do
          it 'calls NotificationService#changed_iteration_issue' do
            expect_next_instance_of(NotificationService::Async) do |ns|
              expect(ns).to receive(:changed_iteration_issue)
            end

            update_issue(iteration: iteration)
          end
        end

        context 'when issue already has an iteration' do
          let_it_be(:old_iteration) { create(:iteration, group: group) }

          before do
            update_issue(iteration: old_iteration)
          end

          context 'setting to nil' do
            it 'calls NotificationService#removed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:removed_iteration_issue)
              end

              update_issue(iteration: nil)
            end
          end

          context 'setting to IssuableFinder::Params::NONE' do
            it 'calls NotificationService#removed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:removed_iteration_issue)
              end

              update_issue(sprint_id: IssuableFinder::Params::NONE)
            end

            it 'removes the iteration properly' do
              update_issue(sprint_id: IssuableFinder::Params::NONE)

              expect(issue.reload.iteration).to be_nil
            end
          end

          context 'setting to another iteration' do
            it 'calls NotificationService#changed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:changed_iteration_issue)
              end

              update_issue(iteration: iteration)
            end
          end
        end
      end

      context 'updating weight' do
        before do
          project.add_maintainer(user)
          issue.update!(weight: 3)
        end

        context 'when weight is integer' do
          it 'updates to the exact value' do
            expect { update_issue(weight: 2) }.to change { issue.weight }.to(2)
          end
        end

        context 'when weight is float' do
          it 'rounds the value down' do
            expect { update_issue(weight: 1.8) }.to change { issue.weight }.to(1)
          end
        end

        context 'when weight is zero' do
          it 'sets the value to zero' do
            expect { update_issue(weight: 0) }.to change { issue.weight }.to(0)
          end
        end

        context 'when weight is a string' do
          it 'sets the value to 0' do
            expect { update_issue(weight: 'abc') }.to change { issue.weight }.to(0)
          end
        end
      end

      it_behaves_like 'updating issuable health status' do
        let(:issuable) { issue }
        let(:parent) { project }
      end

      context 'updating other fields' do
        it 'does not call UpdateDatesService' do
          expect(Epics::UpdateDatesService).not_to receive(:new)
          update_issue(title: 'foo')
        end
      end
    end

    context 'assigning iteration' do
      before do
        stub_licensed_features(iterations: true)
        group.add_maintainer(user)
      end

      RSpec.shared_examples 'creates iteration resource event' do
        it 'creates a system note' do
          expect do
            update_issue(iteration: iteration)
          end.not_to change { Note.system.count }
        end

        it 'does not create a iteration change event' do
          expect do
            update_issue(iteration: iteration)
          end.to change { ResourceIterationEvent.count }.by(1)
        end
      end

      context 'group iterations' do
        let_it_be(:iteration) { create(:iteration, group: group) }

        it_behaves_like 'creates iteration resource event'
      end

      context 'project iterations' do
        let_it_be(:iteration) { create(:iteration, :skip_project_validation, project: project) }

        it_behaves_like 'creates iteration resource event'
      end
    end

    context 'changing issue_type' do
      let_it_be(:sla_setting) { create(:project_incident_management_setting, :sla_enabled, project: project) }

      before do
        stub_licensed_features(incident_sla: true, quality_management: true)
      end

      context 'from issue to incident' do
        it 'creates an SLA' do
          expect { update_issue(issue_type: 'incident') }.to change(IssuableSla, :count).by(1)
          expect(issue.reload).to be_incident
          expect(issue.reload.issuable_sla).to be_present
        end
      end

      context 'from incident to issue' do
        let_it_be(:issue) { create(:incident, project: project) }
        let_it_be(:sla) { create(:issuable_sla, issue: issue) }

        it 'does not remove the SLA or create a new one' do
          expect { update_issue(issue_type: 'issue') }.not_to change(IssuableSla, :count)
          expect(issue.reload.issue_type).to eq('issue')
          expect(issue.reload.issuable_sla).to be_present
        end
      end

      context 'from issue to restricted issue types' do
        context 'with permissions' do
          it 'changes the type' do
            expect { update_issue(issue_type: 'test_case') }
              .to change { issue.reload.issue_type }
              .from('issue')
              .to('test_case')
          end

          it 'does not create or remove an SLA' do
            expect { update_issue(issue_type: 'test_case') }.not_to change(IssuableSla, :count)
            expect(issue.issuable_sla).to be_nil
          end
        end

        context 'without sufficient permissions' do
          let_it_be(:guest) { create(:user) }

          let(:user) { guest }

          before do
            project.add_guest(guest)
          end

          it 'excludes the issue type param' do
            expect { update_issue(issue_type: 'test_case') }.not_to change { issue.reload.issue_type }
          end
        end
      end
    end

    context 'assigning epic' do
      before do
        stub_licensed_features(epics: true)
      end

      let(:params) { { epic: epic } }

      subject { update_issue(params) }

      context 'when a user does not have permissions to assign an epic' do
        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_maintainer(user)
        end

        context 'when EpicIssues::CreateService returns failure', :aggregate_failures do
          it 'does not send usage data for added or changed epic action' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
                                                   .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
                                                   .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :failure })

            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_added_to_epic_action)

            subject
          end
        end

        context 'when issue does not belong to an epic yet' do
          it 'assigns an issue to the provided epic' do
            expect { update_issue(epic: epic) }.to change { issue.reload.epic }.from(nil).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          it 'tracks usage data for added to epic action' do
            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_added_to_epic_action).with(author: user)

            subject
          end
        end

        context 'when issue belongs to another epic' do
          let_it_be(:epic2) { create(:epic, group: group) }

          before do
            issue.update!(epic: epic2)
          end

          it 'assigns the issue passed to the provided epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic2).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          it 'tracks usage data for changed epic action' do
            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_changed_epic_action).with(author: user)

            subject
          end
        end

        context 'when updating issue epic and milestone and assignee attributes' do
          let_it_be(:milestone) { create(:milestone, project: project) }
          let_it_be(:assignee_user1) { create(:user) }

          let(:params) { { epic: epic, milestone: milestone, assignees: [assignee_user1] } }

          before do
            project.add_guest(assignee_user1)
          end

          it 'assigns the issue passed to the provided epic', :sidekiq_inline do
            expect do
              subject
              issue.reload
            end.to change { issue.epic }.from(nil).to(epic)
                   .and(change { issue.milestone }.from(nil).to(milestone))
                   .and(change(ResourceMilestoneEvent, :count).by(1))
                   .and(change(Note, :count).by(3))
          end

          context 'when milestone and epic attributes are changed from description' do
            let(:params) { { description: %(/epic #{epic.to_reference}\n/milestone #{milestone.to_reference}\n/assign #{assignee_user1.to_reference}) } }

            it 'assigns the issue passed to the provided epic', :sidekiq_inline do
              expect do
                subject
                issue.reload
              end.to change { issue.epic }.from(nil).to(epic)
                     .and(change { issue.assignees }.from([]).to([assignee_user1]))
                     .and(change { issue.milestone }.from(nil).to(milestone))
                     .and(change(ResourceMilestoneEvent, :count).by(1))
                     .and(change(Note, :count).by(4))
            end
          end

          context 'when assigning epic raises an exception' do
            let(:mock_service) { double('service', execute: { status: :error, message: 'failed to assign epic' }) }

            it 'assigns the issue passed to the provided epic' do
              expect(EpicIssues::CreateService).to receive(:new).and_return(mock_service)

              expect { subject }.to raise_error(EE::Issues::BaseService::EpicAssignmentError, 'failed to assign epic')
            end
          end
        end
      end
    end

    context 'removing epic' do
      before do
        stub_licensed_features(epics: true)
      end

      subject { update_issue(epic: nil) }

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_maintainer(user)
        end

        context 'when issue does not belong to an epic yet' do
          it 'does not do anything' do
            expect { subject }.not_to change { issue.reload.epic }
          end

          it 'does not send usage data for removed epic action' do
            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_removed_from_epic_action)

            subject
          end
        end

        context 'when issue belongs to an epic' do
          before do
            issue.update!(epic: epic)
          end

          it 'unassigns the epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
          end

          it 'calls EpicIssues::DestroyService' do
            link_sevice = double
            expect(EpicIssues::DestroyService).to receive(:new).with(EpicIssue.last, user).and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end

          it 'tracks usage data for removed from epic action' do
            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_removed_from_epic_action).with(author: user)

            subject
          end

          context 'but EpicIssues::DestroyService returns failure', :aggregate_failures do
            it 'does not send usage data for removed epic action' do
              link_sevice = double
              expect(EpicIssues::DestroyService).to receive(:new).with(EpicIssue.last, user).and_return(link_sevice)
              expect(link_sevice).to receive(:execute).and_return({ status: :failure })
              expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_removed_from_epic_action)

              subject
            end
          end
        end
      end
    end

    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { issue }
      let(:parent) { project }
    end

    it_behaves_like 'issue with epic_id parameter' do
      let(:execute) { described_class.new(project: project, current_user: user, params: params).execute(issue) }
    end

    context 'when epic_id is nil' do
      before do
        stub_licensed_features(epics: true)
        group.add_maintainer(user)
        issue.update!(epic: epic)
      end

      let(:epic_issue) { issue.epic_issue }
      let(:params) { { epic_id: nil } }

      subject { update_issue(params) }

      it 'removes epic issue link' do
        expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
      end

      it 'calls EpicIssues::DestroyService' do
        link_sevice = double
        expect(EpicIssues::DestroyService).to receive(:new).with(epic_issue, user).and_return(link_sevice)
        expect(link_sevice).to receive(:execute).and_return({ status: :success })

        subject
      end
    end

    context 'promoting to epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)
      end

      context 'when promote_to_epic param is present' do
        it 'promotes issue to epic' do
          expect { update_issue(promote_to_epic: true) }.to change { Epic.count }.by(1)
          expect(issue.promoted_to_epic_id).not_to be_nil
        end
      end

      context 'when promote_to_epic param is not present' do
        it 'does not promote issue to epic' do
          expect { update_issue(promote_to_epic: false) }.not_to change { Epic.count }
          expect(issue.promoted_to_epic_id).to be_nil
        end
      end
    end

    describe 'publish to status page' do
      let(:execute) { update_issue(params) }
      let(:issue_id) { execute&.id }

      before do
        create(:status_page_published_incident, issue: issue)
      end

      context 'when update succeeds' do
        let(:params) { { title: 'New title' } }

        include_examples 'trigger status page publish'
      end

      context 'when closing' do
        let(:params) { { state_event: 'close' } }

        include_examples 'trigger status page publish'
      end

      context 'when reopening' do
        let(:issue) { create(:issue, :closed, project: project) }
        let(:params) { { state_event: 'reopen' } }

        include_examples 'trigger status page publish'
      end

      context 'when update fails' do
        let(:params) { { title: nil } }

        include_examples 'no trigger status page publish'
      end
    end
  end
end
