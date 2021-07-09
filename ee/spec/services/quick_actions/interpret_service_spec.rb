# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuickActions::InterpretService do
  let(:current_user) { create(:user) }
  let(:developer) { create(:user) }
  let(:developer2) { create(:user) }
  let(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_refind(:project) { create(:project, :repository, :public, group: group) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }

  let(:service) { described_class.new(project, current_user) }

  before do
    stub_licensed_features(multiple_issue_assignees: true,
                           multiple_merge_request_reviewers: true,
                           multiple_merge_request_assignees: true)

    project.add_developer(current_user)
    project.add_developer(developer)
  end

  shared_examples 'quick action is unavailable' do |action|
    it 'does not recognize action' do
      expect(service.available_commands(target).map { |command| command[:name] }).not_to include(action)
    end
  end

  shared_examples 'quick action is available' do |action|
    it 'does recognize action' do
      expect(service.available_commands(target).map { |command| command[:name] }).to include(action)
    end
  end

  shared_examples 'adds quick action parameter' do |parameter_key, quick_action|
    let(:content) { "/#{quick_action} #{referenced_epic&.to_reference(epic)}" }

    it 'adds parameter to updates array' do
      _, updates = service.execute(content, epic)

      expect(updates[parameter_key]).to eq(referenced_epic)
    end
  end

  shared_examples 'does not add quick action parameter' do |parameter_key, quick_action|
    let(:content) { "/#{quick_action} #{referenced_epic&.to_reference(epic)}" }

    it 'does not add parameter to updates array' do
      _, updates = service.execute(content, epic)

      expect(updates[parameter_key]).to eq(nil)
    end
  end

  shared_examples 'returns execution messages' do |relation|
    context 'when correct epic reference' do
      let(:content) { "/#{relation}_epic #{epic2&.to_reference(epic)}" }
      let(:explain_action) { relation == :child ? 'Adds' : 'Sets'}
      let(:execute_action) { relation == :child ? 'Added' : 'Set'}
      let(:article)        { relation == :child ? 'a' : 'the'}

      it 'returns explain message with epic reference' do
        _, explanations = service.explain(content, epic)
        expect(explanations)
          .to eq(["#{explain_action} #{epic2.group.name}&#{epic2.iid} as #{relation} epic."])
      end

      it 'returns successful execution message' do
        _, _, message = service.execute(content, epic)

        expect(message)
          .to eq("#{execute_action} #{epic2.group.name}&#{epic2.iid} as #{article} #{relation} epic.")
      end
    end

    context 'when epic reference is wrong' do |relation|
      let(:content) { "/#{relation}_epic qwe" }

      it 'returns empty explain message' do
        _, explanations = service.explain(content, epic)
        expect(explanations).to eq([])
      end
    end
  end

  describe '#execute' do
    let(:merge_request) { create(:merge_request, source_project: project) }

    context 'assign command' do
      context 'Issue' do
        it 'fetches assignees and populates them if content contains /assign' do
          issue.update!(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/unassign @#{user2.username}\n/assign @#{user3.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id, user3.id])
        end

        context 'with test_case issue type' do
          it 'does not mark to update assignee' do
            test_case = create(:quality_test_case, project: project)

            _, updates = service.execute("/assign @#{user3.username}", test_case)

            expect(updates[:assignee_ids]).to eq(nil)
          end
        end

        context 'assign command with multiple assignees' do
          it 'fetches assignee and populates assignee_ids if content contains /assign' do
            issue.update!(assignee_ids: [user.id])

            _, updates = service.execute("/unassign @#{user.username}\n/assign @#{user2.username} @#{user3.username}", issue)

            expect(updates[:assignee_ids]).to match_array([user2.id, user3.id])
          end
        end
      end

      context 'Merge Request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it 'fetches assignees and populates them if content contains /assign' do
          merge_request.update(assignee_ids: [user.id])

          _, updates = service.execute("/assign @#{user2.username}", merge_request)

          expect(updates[:assignee_ids]).to match_array([user.id, user2.id])
        end

        context 'assign command with multiple assignees' do
          it 'fetches assignee and populates assignee_ids if content contains /assign' do
            merge_request.update(assignee_ids: [user.id])

            _, updates = service.execute("/assign @#{user.username}\n/assign @#{user2.username} @#{user3.username}", issue)

            expect(updates[:assignee_ids]).to match_array([user.id, user2.id, user3.id])
          end

          context 'unlicensed' do
            before do
              stub_licensed_features(multiple_merge_request_assignees: false)
            end

            it 'does not recognize /assign with multiple user references' do
              merge_request.update(assignee_ids: [user.id])

              _, updates = service.execute("/assign @#{user2.username} @#{user3.username}", merge_request)

              expect(updates[:assignee_ids]).to match_array([user2.id])
            end
          end
        end
      end
    end

    context 'assign_reviewer command' do
      context 'with a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it 'fetches reviewers and populates them if content contains /assign_reviewer' do
          merge_request.update(reviewer_ids: [user.id])

          _, updates = service.execute("/assign_reviewer @#{user2.username}\n/assign_reviewer @#{user3.username}", merge_request)

          expect(updates[:reviewer_ids]).to match_array([user.id, user2.id, user3.id])
        end

        context 'assign command with multiple reviewers' do
          it 'assigns multiple reviewers while respecting previous assignments' do
            merge_request.update(reviewer_ids: [user.id])

            _, updates = service.execute("/assign_reviewer @#{user.username}\n/assign_reviewer @#{user2.username} @#{user3.username}", merge_request)

            expect(updates[:reviewer_ids]).to match_array([user.id, user2.id, user3.id])
          end
        end
      end
    end

    context 'unassign_reviewer command' do
      let(:content) { '/unassign_reviewer' }
      let(:merge_request) { create(:merge_request, source_project: project) }

      context 'unassign_reviewer command with multiple assignees' do
        it 'unassigns both reviewers if content contains /unassign_reviewer @user @user1' do
          merge_request.update(reviewer_ids: [user.id, user2.id, user3.id])

          _, updates = service.execute("/unassign_reviewer @#{user.username} @#{user2.username}", merge_request)

          expect(updates[:reviewer_ids]).to match_array([user3.id])
        end
      end
    end

    context 'unassign command' do
      let(:content) { '/unassign' }

      context 'Issue' do
        it 'unassigns user if content contains /unassign @user' do
          issue.update!(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign @#{user2.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id, user3.id])
        end

        it 'unassigns both users if content contains /unassign @user @user1' do
          issue.update!(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign @#{user2.username} @#{user3.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id])
        end

        it 'unassigns all the users if content contains /unassign' do
          issue.update!(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign", issue)

          expect(updates[:assignee_ids]).to be_empty
        end
      end

      context 'Merge Request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it 'unassigns user if content contains /unassign @user' do
          merge_request.update(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/unassign @#{user2.username}", merge_request)

          expect(updates[:assignee_ids]).to match_array([user.id])
        end

        context 'unassign command with multiple assignees' do
          it 'unassigns both users if content contains /unassign @user @user1' do
            merge_request.update(assignee_ids: [user.id, user2.id, user3.id])

            _, updates = service.execute("/unassign @#{user.username} @#{user2.username}", merge_request)

            expect(updates[:assignee_ids]).to match_array([user3.id])
          end

          context 'unlicensed' do
            before do
              stub_licensed_features(multiple_merge_request_assignees: false)
            end

            it 'does not recognize /unassign @user' do
              merge_request.update(assignee_ids: [user.id, user2.id, user3.id])

              _, updates = service.execute("/unassign @#{user.username}", merge_request)

              expect(updates[:assignee_ids]).to be_empty
            end
          end
        end
      end
    end

    context 'reassign command' do
      let(:content) { "/reassign @#{current_user.username}" }

      context 'Merge Request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        context 'unlicensed' do
          before do
            stub_licensed_features(multiple_merge_request_assignees: false)
          end

          it 'does not recognize /reassign @user' do
            _, updates = service.execute(content, merge_request)

            expect(updates).to be_empty
          end
        end

        it 'reassigns user if content contains /reassign @user' do
          _, updates = service.execute("/reassign @#{current_user.username}", merge_request)

          expect(updates[:assignee_ids]).to match_array([current_user.id])
        end
      end

      context 'Issue' do
        let(:content) { "/reassign @#{current_user.username}" }

        before do
          issue.update!(assignee_ids: [user.id])
        end

        context 'unlicensed' do
          before do
            stub_licensed_features(multiple_issue_assignees: false)
          end

          it 'does not recognize /reassign @user' do
            _, updates = service.execute(content, issue)

            expect(updates).to be_empty
          end
        end

        it 'reassigns user if content contains /reassign @user' do
          _, updates = service.execute("/reassign @#{current_user.username}", issue)

          expect(updates[:assignee_ids]).to match_array([current_user.id])
        end

        context 'with test_case issue type' do
          it 'does not mark to update assignee' do
            test_case = create(:quality_test_case, project: project)

            _, updates = service.execute("/reassign @#{current_user.username}", test_case)

            expect(updates[:assignee_ids]).to eq(nil)
          end
        end
      end
    end

    context 'reassign_reviewer command' do
      let(:content) { "/reassign_reviewer @#{current_user.username}" }

      context 'unlicensed' do
        before do
          stub_licensed_features(multiple_merge_request_reviewers: false)
        end

        it 'does not recognize /reassign_reviewer @user' do
          content = "/reassign_reviewer @#{current_user.username}"
          _, updates = service.execute(content, merge_request)

          expect(updates).to be_empty
        end
      end

      it 'reassigns reviewer if content contains /reassign_reviewer @user' do
        _, updates = service.execute("/reassign_reviewer @#{current_user.username}", merge_request)

        expect(updates[:reviewer_ids]).to match_array([current_user.id])
      end
    end

    context 'iteration command' do
      let_it_be(:iteration) { create(:iteration, group: group) }

      let(:content) { "/iteration #{iteration.to_reference(project)}" }

      context 'when iterations are enabled' do
        before do
          stub_licensed_features(iterations: true)
        end

        context 'when iteration exists' do
          context 'with permissions' do
            before do
              group.add_developer(current_user)
            end

            it 'assigns an iteration to an issue' do
              _, updates, message = service.execute(content, issue)

              expect(updates).to eq(iteration: iteration)
              expect(message).to eq("Set the iteration to #{iteration.to_reference}.")
            end

            context 'when iteration is started' do
              before do
                iteration.start!
              end

              it 'assigns an iteration to an issue' do
                _, updates, message = service.execute(content, issue)

                expect(updates).to eq(iteration: iteration)
                expect(message).to eq("Set the iteration to #{iteration.to_reference}.")
              end
            end
          end

          context 'when the user does not have enough permissions' do
            before do
              allow(current_user).to receive(:can?).with(:use_quick_actions).and_return(true)
              allow(current_user).to receive(:can?).with(:admin_issue, project).and_return(false)
            end

            it 'returns an error message' do
              _, updates, message = service.execute(content, issue)

              expect(updates).to be_empty
              expect(message).to eq('Could not apply iteration command.')
            end
          end
        end

        context 'when iteration does not exist' do
          let(:content) { "/iteration none" }

          it 'returns empty message' do
            _, updates, message = service.execute(content, issue)

            expect(updates).to be_empty
            expect(message).to be_empty
          end
        end
      end

      context 'when iterations are disabled' do
        before do
          stub_licensed_features(iterations: false)
        end

        it 'does not recognize /iteration' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end

      context 'when issuable does not support iterations' do
        it 'does not assign an iteration to an incident' do
          incident = create(:incident, project: project)

          _, updates = service.execute(content, incident)

          expect(updates).to be_empty
        end
      end
    end

    context 'remove_iteration command' do
      let_it_be(:iteration) { create(:iteration, group: group) }

      let(:content) { '/remove_iteration' }

      context 'when iterations are enabled' do
        before do
          stub_licensed_features(iterations: true)
          issue.update!(iteration: iteration)
        end

        it 'removes an assigned iteration from an issue' do
          _, updates, message = service.execute(content, issue)

          expect(updates).to eq(iteration: nil)
          expect(message).to eq("Removed #{iteration.to_reference} iteration.")
        end

        context 'when the user does not have enough permissions' do
          before do
            allow(current_user).to receive(:can?).with(:use_quick_actions).and_return(true)
            allow(current_user).to receive(:can?).with(:admin_issue, project).and_return(false)
          end

          it 'returns an error message' do
            _, updates, message = service.execute(content, issue)

            expect(updates).to be_empty
            expect(message).to eq('Could not apply remove_iteration command.')
          end
        end
      end

      context 'when iterations are disabled' do
        before do
          stub_licensed_features(iterations: false)
        end

        it 'does not recognize /remove_iteration' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end

      context 'when issuable does not support iterations' do
        it 'does not assign an iteration to an incident' do
          incident = create(:incident, project: project)

          _, updates = service.execute(content, incident)

          expect(updates).to be_empty
        end
      end
    end

    context 'epic command' do
      let(:epic) { create(:epic, group: group) }
      let(:content) { "/epic #{epic.to_reference(project)}" }

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        context 'when epic exists' do
          it 'assigns an issue to an epic' do
            _, updates, message = service.execute(content, issue)

            expect(updates).to eq(epic: epic)
            expect(message).to eq('Added an issue to an epic.')
          end

          context 'when an issue belongs to a project without group' do
            let(:user_project) { create(:project) }
            let(:issue)        { create(:issue, project: user_project) }

            before do
              user_project.add_developer(user)
            end

            it 'does not assign an issue to an epic' do
              _, updates = service.execute(content, issue)

              expect(updates).to be_empty
            end
          end

          context 'when issue is already added to epic' do
            it 'returns error message' do
              issue = create(:issue, project: project, epic: epic)

              _, updates, message = service.execute(content, issue)

              expect(updates).to be_empty
              expect(message).to eq("Issue #{issue.to_reference} has already been added to epic #{epic.to_reference}.")
            end
          end

          context 'when issuable does not support epics' do
            it 'does not assign an incident to an epic' do
              incident = create(:incident, project: project)

              _, updates = service.execute(content, incident)

              expect(updates).to be_empty
            end
          end
        end

        context 'when epic does not exist' do
          let(:content) { "/epic none" }

          it 'does not assign an issue to an epic' do
            _, updates, message = service.execute(content, issue)

            expect(updates).to be_empty
            expect(message).to eq("This epic does not exist or you don't have sufficient permission.")
          end
        end

        context 'when user has no permissions to read epic' do
          let(:content) { "/epic #{epic.to_reference(project)}" }

          before do
            allow(current_user).to receive(:can?).with(:use_quick_actions).and_return(true)
            allow(current_user).to receive(:can?).with(:admin_issue, issue).and_return(true)
            allow(current_user).to receive(:can?).with(:read_epic, epic).and_return(false)
          end

          it 'does not assign an issue to an epic' do
            _, updates, message = service.execute(content, issue)

            expect(updates).to be_empty
            expect(message).to eq("This epic does not exist or you don't have sufficient permission.")
          end
        end
      end

      context 'when epics are disabled' do
        it 'does not recognize /epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end
    end

    context 'parent_epic command' do
      let(:epic) { create(:epic, group: group) }
      let(:epic2) { create(:epic, group: group) }
      let(:referenced_epic) { create(:epic, group: epic.group) }

      before do
        group.add_developer(current_user)
        stub_licensed_features(epics: true, subepics: true)
      end

      it_behaves_like 'adds quick action parameter', :quick_action_assign_to_parent_epic, :parent_epic

      context 'when target epic is not persisted yet' do
        let(:epic) { build(:epic, group: group) }
        let(:referenced_epic) { epic2 }

        it_behaves_like 'adds quick action parameter', :quick_action_assign_to_parent_epic, :parent_epic
      end
    end

    context 'child_epic command' do
      let(:subgroup) { create(:group, parent: group) }
      let(:another_group) { create(:group) }
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:epic) { create(:epic, group: group) }
      let(:child_epic) { create(:epic, group: group) }
      let(:referenced_epic) { child_epic }

      context 'when subepics are enabled' do
        before do
          stub_licensed_features(epics: true, subepics: true)
        end

        context 'when a user does not have permissions to add epic relations' do
          it_behaves_like 'does not add quick action parameter', :quick_action_assign_child_epic, :child_epic
          it_behaves_like 'quick action is unavailable', :child_epic do
            let(:target) { epic }
          end
        end

        context 'when a user has permissions to add epic relations' do
          before do
            group.add_developer(current_user)
            another_group.add_developer(current_user)
          end

          it_behaves_like 'adds quick action parameter', :quick_action_assign_child_epic, :child_epic

          it_behaves_like 'quick action is available', :child_epic do
            let(:target) { epic }
          end

          it_behaves_like 'quick action is unavailable', :child_epic do
            let(:target) { issue }
          end

          it_behaves_like 'quick action is unavailable', :child_epic do
            let(:target) { merge_request }
          end

          context 'when target epic is not persisted yet' do
            let(:epic) { build(:epic, group: group) }

            it_behaves_like 'adds quick action parameter', :quick_action_assign_child_epic, :child_epic
          end

          context 'when passed child epic is nil' do
            let(:child_epic) { nil }

            it_behaves_like 'does not add quick action parameter', :quick_action_assign_child_epic, :child_epic

            it 'does not raise error' do
              content = "/child_epic "

              expect { service.execute(content, epic) }.not_to raise_error
            end
          end

          context 'when child_epic is already linked to an epic' do
            let(:referenced_epic) { create(:epic, group: group) }

            before do
              child_epic.update!(parent: referenced_epic)
            end

            it_behaves_like 'quick action is available', :child_epic do
              let(:target) { epic }
            end
          end

          context 'when child epic is in a subgroup of parent epic' do
            let(:referenced_epic) { create(:epic, group: subgroup) }

            it_behaves_like 'quick action is available', :child_epic do
              let(:target) { epic }
            end
          end

          context 'when child epic is in a parent group of the parent epic' do
            let(:referenced_epic) { create(:epic, group: group) }

            before do
              epic.update!(group: subgroup)
            end

            it_behaves_like 'quick action is available', :child_epic do
              let(:target) { epic }
            end
          end

          context 'when child epic is in a different group than parent epic' do
            let(:referenced_epic) { create(:epic, group: another_group) }

            it_behaves_like 'quick action is available', :child_epic do
              let(:target) { epic }
            end
          end
        end
      end

      context 'when epics are disabled' do
        before do
          group.add_developer(current_user)
        end

        it_behaves_like 'does not add quick action parameter', :quick_action_assign_child_epic, :child_epic
        it_behaves_like 'quick action is unavailable', :child_epic do
          let(:target) { epic }
        end
      end
    end

    context 'remove_child_epic command' do
      let(:subgroup) { create(:group, parent: group) }
      let(:another_group) { create(:group) }
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:epic) { create(:epic, group: group) }
      let!(:child_epic) { create(:epic, group: group, parent: epic) }
      let(:content) { "/remove_child_epic #{child_epic.to_reference(epic)}" }

      shared_examples 'epic relation is not removed' do
        it 'does not remove child_epic from epic' do
          expect(child_epic.parent).to eq(epic)

          service.execute(content, target)
          child_epic.reload

          expect(child_epic.parent).to eq(epic)
        end
      end

      shared_examples 'epic relation is removed' do
        it 'does not remove child_epic from epic' do
          expect(child_epic.parent).to eq(epic)

          service.execute(content, epic)
          child_epic.reload

          expect(child_epic.parent).to be_nil
        end
      end

      context 'when subepics are enabled' do
        before do
          stub_licensed_features(epics: true, subepics: true)
          epic.reload
        end

        context 'when a user does not have permissions to remove epic relations' do
          it 'does not remove child_epic from epic' do
            expect(child_epic.parent).to eq(epic)

            service.execute(content, epic)
            child_epic.reload

            expect(child_epic.parent).to eq(epic)
          end

          it_behaves_like 'epic relation is not removed' do
            let(:target) { epic }
          end

          it_behaves_like 'quick action is unavailable', :remove_child_epic do
            let(:target) { epic }
          end
        end

        context 'when a user has permissions to remove epic relations' do
          before do
            group.add_developer(current_user)
            another_group.add_developer(current_user)
          end

          it_behaves_like 'quick action is available', :remove_child_epic do
            let(:target) { epic }
          end

          it_behaves_like 'quick action is unavailable', :remove_child_epic do
            let(:target) { issue }
          end

          it_behaves_like 'quick action is unavailable', :remove_child_epic do
            let(:target) { merge_request }
          end

          context 'when target epic is not persisted yet' do
            let(:target) { build(:epic, group: group) }

            it_behaves_like 'quick action is unavailable', :remove_child_epic
          end

          it_behaves_like 'epic relation is removed'

          context 'when trying to remove child epic from a different epic' do
            let(:another_epic) { create(:epic, group: group) }

            it_behaves_like 'epic relation is not removed' do
              let(:target) { another_epic }
            end
          end

          context 'when child epic is in a subgroup of parent epic' do
            let(:child_epic) { create(:epic, group: subgroup, parent: epic) }

            it_behaves_like 'epic relation is removed'
            it_behaves_like 'quick action is available', :remove_child_epic do
              let(:target) { epic }
            end
          end

          context 'when child and parent epics are in different groups' do
            let(:child_epic) { create(:epic, group: group, parent: epic) }

            context 'when child epic is in a parent group of the parent epic' do
              before do
                epic.update!(group: subgroup)
              end

              it_behaves_like 'epic relation is removed' do
                let(:target) { epic }
              end

              it_behaves_like 'quick action is available', :remove_child_epic do
                let(:target) { epic }
              end
            end

            context 'when child epic is in a different group than parent epic' do
              before do
                epic.update!(group: another_group)
              end

              it_behaves_like 'epic relation is removed' do
                let(:target) { epic }
              end

              it_behaves_like 'quick action is available', :remove_child_epic do
                let(:target) { epic }
              end
            end
          end
        end
      end

      context 'when subepics are disabled' do
        before do
          stub_licensed_features(epics: true, subepics: false)
          group.add_developer(current_user)
        end

        it_behaves_like 'epic relation is not removed' do
          let(:target) { epic }
        end

        it_behaves_like 'quick action is unavailable', :remove_child_epic do
          let(:target) { epic }
        end
      end
    end

    context 'label command for epics' do
      let(:epic) { create(:epic, group: group) }
      let(:label) { create(:group_label, title: 'bug', group: group) }
      let(:project_label) { create(:label, title: 'project_label') }
      let(:content) { "/label ~#{label.title} ~#{project_label.title}" }

      let(:service) { described_class.new(nil, current_user) }

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        context 'when a user has permissions to label an epic' do
          before do
            group.add_developer(current_user)
          end

          it 'populates valid label ids' do
            _, updates = service.execute(content, epic)

            expect(updates).to eq(add_label_ids: [label.id])
          end
        end

        context 'when a user does not have permissions to label an epic' do
          it 'does not populate any labels' do
            _, updates = service.execute(content, epic)

            expect(updates).to be_empty
          end
        end
      end

      context 'when epics are disabled' do
        it 'does not populate any labels' do
          group.add_developer(current_user)

          _, updates = service.execute(content, epic)

          expect(updates).to be_empty
        end
      end
    end

    context 'remove_epic command' do
      let(:epic) { create(:epic, group: group) }
      let(:content) { "/remove_epic" }

      before do
        stub_licensed_features(epics: true)
        issue.update!(epic: epic)
      end

      context 'when epics are disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not recognize /remove_epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end

      context 'when subepics are enabled' do
        before do
          stub_licensed_features(epics: true, subepics: true)
        end

        it 'unassigns an issue from an epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to eq(epic: nil)
        end
      end

      context 'when issuable does not support epics' do
        it 'does not recognize /remove_epic' do
          incident = create(:incident, project: project, epic: epic)

          _, updates = service.execute(content, incident)

          expect(updates).to be_empty
        end
      end
    end

    context 'approve command' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:content) { '/approve' }

      it 'approves the current merge request' do
        service.execute(content, merge_request)

        expect(merge_request.approved_by_users).to eq([current_user])
      end

      context "when the user can't approve" do
        before do
          project.team.truncate
          project.add_guest(current_user)
        end

        it 'does not approve the MR' do
          service.execute(content, merge_request)

          expect(merge_request.approved_by_users).to be_empty
        end
      end
    end

    shared_examples 'weight command' do
      it 'populates weight specified by the /weight command' do
        _, updates = service.execute(content, issuable)

        expect(updates).to eq(weight: weight)
      end
    end

    shared_examples 'clear weight command' do
      it 'populates weight: nil if content contains /clear_weight' do
        issuable.update!(weight: 5)

        _, updates = service.execute(content, issuable)

        expect(updates).to eq(weight: nil)
      end
    end

    context 'issuable weights licensed' do
      let(:issuable) { issue }

      before do
        stub_licensed_features(issue_weights: true)
      end

      context 'weight' do
        let(:content) { "/weight #{weight}" }

        it_behaves_like 'weight command' do
          let(:weight) { 5 }
        end

        it_behaves_like 'weight command' do
          let(:weight) { 0 }
        end

        context 'when weight is negative' do
          it 'does not populate weight' do
            content = "/weight -10"
            _, updates = service.execute(content, issuable)

            expect(updates).to be_empty
          end
        end
      end

      context 'clear_weight' do
        it_behaves_like 'clear weight command' do
          let(:content) { '/clear_weight' }
        end
      end
    end

    context 'issuable weights unlicensed' do
      before do
        stub_licensed_features(issue_weights: false)
      end

      it 'does not recognise /weight X' do
        _, updates = service.execute('/weight 5', issue)

        expect(updates).to be_empty
      end

      it 'does not recognise /clear_weight' do
        _, updates = service.execute('/clear_weight', issue)

        expect(updates).to be_empty
      end
    end

    context 'issuable weights not supported by type' do
      let_it_be(:incident) { create(:incident, project: project) }

      before do
        stub_licensed_features(issue_weights: true)
      end

      it 'does not recognise /weight X' do
        _, updates = service.execute('/weight 5', incident)

        expect(updates).to be_empty
      end

      it 'does not recognise /clear_weight' do
        _, updates = service.execute('/clear_weight', incident)

        expect(updates).to be_empty
      end
    end

    shared_examples 'empty command' do
      it 'populates {} if content contains an unsupported command' do
        _, updates = service.execute(content, issuable)

        expect(updates).to be_empty
      end
    end

    context 'not persisted merge request can not be merged' do
      it_behaves_like 'empty command' do
        let(:content) { "/merge" }
        let(:issuable) { build(:merge_request, source_project: project) }
      end
    end

    context 'not approved merge request can not be merged' do
      before do
        merge_request.target_project.update!(approvals_before_merge: 1)
      end

      it_behaves_like 'empty command' do
        let(:content) { "/merge" }
        let(:issuable) { build(:merge_request, source_project: project) }
      end
    end

    context 'approved merge request can be merged' do
      before do
        merge_request.update!(approvals_before_merge: 1)
        merge_request.approvals.create(user: current_user)
      end

      it_behaves_like 'empty command' do
        let(:content) { "/merge" }
        let(:issuable) { build(:merge_request, source_project: project) }
      end
    end

    context 'confidential command' do
      context 'for test cases' do
        it 'does mark to update confidential attribute' do
          issuable = create(:quality_test_case, project: project)

          _, updates, _ = service.execute('/confidential', issuable)

          expect(updates[:confidential]).to eq(true)
        end
      end
    end
  end

  describe '#explain' do
    describe 'unassign command' do
      let(:content) { '/unassign' }
      let(:issue) { create(:issue, project: project, assignees: [user, user2]) }

      it "includes all assignees' references" do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignees @#{user.username} and @#{user2.username}."])
      end
    end

    describe 'unassign command with assignee references' do
      let(:content) { "/unassign @#{user.username} @#{user3.username}" }
      let(:issue) { create(:issue, project: project, assignees: [user, user2, user3]) }

      it 'includes only selected assignee references' do
        _, explanations = service.explain(content, issue)

        expect(explanations.first).to match(/Removes assignees/)
        expect(explanations.first).to match("@#{user3.username}")
        expect(explanations.first).to match("@#{user.username}")
      end
    end

    describe 'weight command' do
      let(:content) { '/weight 4' }

      it 'includes the number' do
        _, explanations = service.explain(content, issue)
        expect(explanations).to eq(['Sets weight to 4.'])
      end
    end

    context 'epic commands' do
      let(:epic) { create(:epic, group: group) }
      let(:epic2) { create(:epic, group: group) }

      before do
        stub_licensed_features(epics: true, subepics: true)
        group.add_developer(current_user)
      end

      shared_examples 'target epic does not exist' do |relation|
        it 'returns unsuccessful execution message' do
          _, _, message = service.execute(content, epic)

          expect(message)
            .to eq("#{relation.capitalize} epic doesn't exist.")
        end
      end

      shared_examples 'epics are already related' do
        it 'returns unsuccessful execution message' do
          _, _, message = service.execute(content, epic)

          expect(message)
            .to eq("Given epic is already related to this epic.")
        end
      end

      shared_examples 'without permissions for action' do
        it 'returns unsuccessful execution message' do
          _, _, message = service.execute(content, epic)

          expect(message)
            .to eq("You don't have sufficient permission to perform this action.")
        end
      end

      context 'child_epic command' do
        it_behaves_like 'returns execution messages', :child

        context 'when epic is already a child epic' do
          let(:content) { "/child_epic #{epic2&.to_reference(epic)}" }

          before do
            epic2.update!(parent: epic)
          end

          it_behaves_like 'epics are already related'
        end

        context 'when epic is the parent epic' do
          let(:content) { "/child_epic #{epic2&.to_reference(epic)}" }

          before do
            epic.update!(parent: epic2)
          end

          it_behaves_like 'epics are already related'
        end

        context 'when epic does not exist' do
          let(:content) { "/child_epic none" }

          it_behaves_like 'target epic does not exist', :child
        end

        context 'when user has no permission to read epic' do
          let(:content) { "/child_epic #{epic2&.to_reference(epic)}" }

          before do
            allow(current_user).to receive(:can?).with(:use_quick_actions).and_return(true)
            allow(current_user).to receive(:can?).with(:admin_epic, epic).and_return(true)
            allow(current_user).to receive(:can?).with(:read_epic, epic2).and_return(false)
          end

          it_behaves_like 'without permissions for action'
        end
      end

      context 'remove_child_epic command' do
        context 'when correct epic reference' do
          let(:content) { "/remove_child_epic #{epic2&.to_reference(epic)}" }

          before do
            epic2.update!(parent: epic)
          end

          it 'returns explain message with epic reference' do
            _, explanations = service.explain(content, epic)

            expect(explanations).to eq(["Removes #{epic2.group.name}&#{epic2.iid} from child epics."])
          end

          it 'returns successful execution message' do
            _, _, message = service.execute(content, epic)

            expect(message)
              .to eq("Removed #{epic2.group.name}&#{epic2.iid} from child epics.")
          end
        end

        context 'when epic reference is wrong' do
          let(:content) { "/child_epic qwe" }

          it 'returns empty explain message' do
            _, explanations = service.explain(content, epic)
            expect(explanations).to eq([])
          end
        end

        context 'when child epic does not exist' do
          let(:content) { "/remove_child_epic #{epic2&.to_reference(epic)}" }

          before do
            epic.update!(parent: nil)
          end

          it 'returns unsuccessful execution message' do
            _, _, message = service.execute(content, epic)

            expect(message)
              .to eq("Child epic does not exist.")
          end
        end
      end

      context 'parent_epic command' do
        let(:referenced_epic) { epic2 }

        it_behaves_like 'returns execution messages', :parent

        context 'when epic is already a parent epic' do
          let(:content) { "/parent_epic #{epic2&.to_reference(epic)}" }

          before do
            epic.update!(parent: epic2)
          end

          it_behaves_like 'epics are already related'
        end

        context 'when epic is a an existing child epic' do
          let(:content) { "/parent_epic #{epic2&.to_reference(epic)}" }

          before do
            epic2.update!(parent: epic)
          end

          it_behaves_like 'epics are already related'
        end

        context 'when epic does not exist' do
          let(:content) { "/parent_epic none" }

          it_behaves_like 'target epic does not exist', :parent
        end

        context 'when user has no permission to read epic' do
          let(:content) { "/parent_epic #{epic2&.to_reference(epic)}" }

          before do
            allow(current_user).to receive(:can?).with(:use_quick_actions).and_return(true)
            allow(current_user).to receive(:can?).with(:admin_epic, epic).and_return(true)
            allow(current_user).to receive(:can?).with(:read_epic, epic2).and_return(false)
          end

          it_behaves_like 'without permissions for action'
        end
      end

      context 'remove_parent_epic command' do
        context 'when parent is present' do
          before do
            epic.parent = epic2
          end

          it 'returns explain message with epic reference' do
            _, explanations = service.explain("/remove_parent_epic", epic)

            expect(explanations).to eq(["Removes parent epic #{epic2.group.name}&#{epic2.iid}."])
          end

          it 'returns successful execution message' do
            _, _, message = service.execute("/remove_parent_epic", epic)

            expect(message)
              .to eq("Removed parent epic #{epic2.group.name}&#{epic2.iid}.")
          end
        end

        context 'when target epic is not persisted yet' do
          let(:target) { build(:epic, group: group) }

          it_behaves_like 'quick action is unavailable', :remove_parent_epic
        end

        context 'when parent is not present' do
          before do
            epic.parent = nil
          end

          it 'returns empty explain message' do
            _, explanations = service.explain("/remove_parent_epic", epic)

            expect(explanations).to eq([])
          end

          it 'returns unsuccessful execution message' do
            _, _, message = service.execute("/remove_parent_epic", epic)

            expect(message)
              .to eq("Parent epic is not present.")
          end
        end
      end
    end
  end
end
