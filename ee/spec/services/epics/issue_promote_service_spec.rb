# frozen_string_literal: true
require 'spec_helper'

describe Epics::IssuePromoteService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:label1) { create(:group_label, group: group) }
  let(:label2) { create(:label, project: project) }
  let(:milestone) { create(:milestone, group: group) }
  let(:description) { 'simple description' }
  let(:issue) do
    create(:issue, project: project, labels: [label1, label2],
                   milestone: milestone, description: description)
  end

  subject { described_class.new(issue.project, user) }

  let(:epic) { Epic.last }

  describe '#execute' do
    context 'when epics are not enabled' do
      it 'raises a permission error' do
        group.add_developer(user)

        expect { subject.execute(issue) }
          .to raise_error(Epics::IssuePromoteService::PromoteError, /permissions/)
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user can not promote the issue' do
        it 'raises a permission error' do
          expect { subject.execute(issue) }
            .to raise_error(Epics::IssuePromoteService::PromoteError, /permissions/)
        end
      end

      context 'when a user can promote the issue' do
        before do
          group.add_developer(user)
        end

        context 'when an issue does not belong to a group' do
          it 'raises an error' do
            other_issue = create(:issue, project: create(:project))

            expect { subject.execute(other_issue) }
              .to raise_error(Epics::IssuePromoteService::PromoteError, /group/)
          end
        end

        context 'when issue is promoted' do
          before do
            allow(Gitlab::Tracking).to receive(:event).with('epics', 'promote', an_instance_of(Hash))

            subject.execute(issue)
          end

          it 'creates a new epic with correct attributes' do
            expect(epic.title).to eq(issue.title)
            expect(epic.description).to eq(issue.description)
            expect(epic.author).to eq(user)
            expect(epic.group).to eq(group)
          end

          it 'copies group labels assigned to the issue' do
            expect(epic.labels).to eq([label1])
          end

          it 'creates a system note on the issue' do
            expect(issue.notes.last.note).to eq("promoted to epic #{epic.to_reference(project)}")
          end

          it 'creates a system note on the epic' do
            expect(epic.notes.last.note).to eq("promoted from issue #{issue.to_reference(group)}")
          end

          it 'closes the original issue' do
            expect(issue).to be_closed
          end

          it 'marks the old issue as promoted' do
            expect(issue).to be_promoted
            expect(issue.promoted_to_epic).to eq(epic)
          end
        end

        context 'when promoted issue has notes' do
          let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

          before do
            allow(Gitlab::Tracking).to receive(:event).with('epics', 'promote', an_instance_of(Hash))
            issue.reload
          end

          it 'creates a new epic with all notes' do
            epic = subject.execute(issue)
            expect(epic.notes.count).to eq(issue.notes.count)
            expect(epic.notes.where(discussion_id: discussion.discussion_id).count).to eq(0)
            expect(issue.notes.where(discussion_id: discussion.discussion_id).count).to eq(1)
          end
        end
      end
    end
  end
end
