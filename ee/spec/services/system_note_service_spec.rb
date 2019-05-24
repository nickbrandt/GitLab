# frozen_string_literal: true

require 'spec_helper'

describe SystemNoteService do
  include ProjectForksHelper
  include Gitlab::Routing
  include RepoHelpers

  set(:group)    { create(:group) }
  set(:project)  { create(:project, :repository, group: group) }
  set(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic, group: group) }

  shared_examples_for 'a system note' do
    let(:expected_noteable) { noteable }
    let(:commit_count)      { nil }

    it 'has the correct attributes', :aggregate_failures do
      expect(subject).to be_valid
      expect(subject).to be_system

      expect(subject.noteable).to eq expected_noteable
      expect(subject.author).to eq author

      expect(subject.system_note_metadata.action).to eq(action)
      expect(subject.system_note_metadata.commit_count).to eq(commit_count)
    end
  end

  shared_examples_for 'a project system note' do
    it 'has the project attribute set' do
      expect(subject.project).to eq project
    end

    it_behaves_like 'a system note'
  end

  describe '.relate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { described_class.relate_issue(noteable, noteable_ref, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'relate' }
    end

    context 'when issue marks another as related' do
      it 'sets the note text' do
        expect(subject.note).to eq "marked this issue as related to #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '.unrelate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { described_class.unrelate_issue(noteable, noteable_ref, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'unrelate' }
    end

    context 'when issue relation is removed' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed the relation with #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '.approve_mr' do
    let(:noteable) { create(:merge_request, source_project: project) }
    subject { described_class.approve_mr(noteable, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'approved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "approved this merge request"
      end
    end
  end

  describe '.unapprove_mr' do
    let(:noteable) { create(:merge_request, source_project: project) }
    subject { described_class.unapprove_mr(noteable, author) }

    it_behaves_like 'a system note' do
      let(:action) { 'unapproved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "unapproved this merge request"
      end
    end
  end

  describe '.change_weight_note' do
    context 'when weight changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: 4) }

      subject { described_class.change_weight_note(noteable, project, author) }

      it_behaves_like 'a project system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed weight to **4**"
      end
    end

    context 'when weight removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: nil) }

      subject { described_class.change_weight_note(noteable, project, author) }

      it_behaves_like 'a project system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the weight'
      end
    end
  end

  describe '.change_epic_date_note' do
    let(:timestamp) { Time.now }

    context 'when start date was changed' do
      let(:noteable) { create(:epic) }

      subject { described_class.change_epic_date_note(noteable, author, 'start date', timestamp) }

      it_behaves_like 'a system note' do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed start date to #{timestamp.strftime('%b %-d, %Y')}"
      end
    end

    context 'when start date was removed' do
      let(:noteable) { create(:epic, start_date: timestamp) }

      subject { described_class.change_epic_date_note(noteable, author, 'start date', nil) }

      it_behaves_like 'a system note' do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the start date'
      end
    end

    context '.issue_promoted' do
      context 'note on the epic' do
        subject { described_class.issue_promoted(epic, issue, author, direction: :from) }

        it_behaves_like 'a system note' do
          let(:action) { 'moved' }
          let(:expected_noteable) { epic }
        end

        it 'sets the note text' do
          expect(subject.note).to eq("promoted from issue #{issue.to_reference(group)}")
        end
      end

      context 'note on the issue' do
        subject { described_class.issue_promoted(issue, epic, author, direction: :to) }

        it_behaves_like 'a system note' do
          let(:action) { 'moved' }
        end

        it 'sets the note text' do
          expect(subject.note).to eq("promoted to epic #{epic.to_reference(project)}")
        end
      end
    end
  end

  describe '.epic_issue' do
    let(:noteable) { epic }
    let(:project) { nil }

    context 'issue added to an epic' do
      subject { described_class.epic_issue(epic, issue, author, :added) }

      it_behaves_like 'a system note' do
        let(:action) { 'epic_issue_added' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("added issue #{issue.to_reference(epic.group)}")
      end
    end

    context 'issue removed from an epic' do
      subject { described_class.epic_issue(epic, issue, author, :removed) }

      it_behaves_like 'a system note' do
        let(:action) { 'epic_issue_removed' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("removed issue #{issue.to_reference(epic.group)}")
      end
    end

    context 'invalid type' do
      it 'raises an error' do
        expect { described_class.issue_on_epic(issue, epic, author, :invalid) }
          .not_to change { Note.count }
      end
    end
  end

  describe '.issue_on_epic' do
    context 'issue added to an epic' do
      subject { described_class.issue_on_epic(issue, epic, author, :added) }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_added_to_epic' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("added to epic #{epic.to_reference(issue.project)}")
      end
    end

    context 'issue removed from an epic' do
      subject { described_class.issue_on_epic(issue, epic, author, :removed) }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_removed_from_epic' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("removed from epic #{epic.to_reference(issue.project)}")
      end
    end

    context 'invalid type' do
      it 'does not create a new note' do
        expect { described_class.issue_on_epic(issue, epic, author, :invalid) }
          .not_to change { Note.count }
      end
    end
  end

  describe '.relate_epic' do
    let(:child_epic) { create(:epic, parent: epic, group: group) }
    let(:noteable) { child_epic }

    subject { described_class.change_epics_relation(epic, child_epic, author, 'relate_epic') }

    it_behaves_like 'a system note' do
      let(:action) { 'relate_epic' }
    end

    context 'when epic is added as child to a parent epic' do
      it 'sets the note text' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
        expect(Note.first.note).to eq("added epic &#{child_epic.iid} as child epic")
        expect(Note.last.note).to eq("added epic &#{epic.iid} as parent epic")
      end
    end

    context 'when added epic is from a subgroup' do
      let(:subgroup) {create(:group, parent: group)}

      before do
        child_epic.update!({ group: subgroup })
      end

      it 'sets the note text' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
        expect(Note.first.note).to eq("added epic #{group.path}/#{subgroup.path}&#{child_epic.iid} as child epic")
        expect(Note.last.note).to eq("added epic #{group.path}&#{epic.iid} as parent epic")
      end
    end
  end

  describe '.unrelate_epic' do
    let(:child_epic) { create(:epic, parent: epic, group: group) }
    let(:noteable) { child_epic }

    subject { described_class.change_epics_relation(epic, child_epic, author, 'unrelate_epic') }

    it_behaves_like 'a system note' do
      let(:action) { 'unrelate_epic' }
    end

    context 'when child epic is removed from a parent epic' do
      it 'sets the note text' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
        expect(Note.first.note).to eq("removed child epic &#{child_epic.iid}")
        expect(Note.last.note).to eq("removed parent epic &#{epic.iid}")
      end
    end

    context 'when removed epic is from a subgroup' do
      let(:subgroup) {create(:group, parent: group)}

      before do
        child_epic.update!({ group: subgroup })
      end

      it 'sets the note text' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
        expect(Note.first.note).to eq("removed child epic #{group.path}/#{subgroup.path}&#{child_epic.iid}")
        expect(Note.last.note).to eq("removed parent epic #{group.path}&#{epic.iid}")
      end
    end
  end

  describe '.merge_train' do
    subject { described_class.merge_train(noteable, project, author, noteable.merge_train) }

    let(:noteable) { create(:merge_request, :on_train, source_project: project, target_project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge train' system note" do
      expect(subject.note).to eq('started a merge train')
    end

    context 'when index of the merge request is not zero' do
      before do
        allow(noteable.merge_train).to receive(:index) { 1 }
      end

      it "posts the 'merge train' system note" do
        expect(subject.note).to eq('added this merge request to the merge train at index 1')
      end
    end
  end

  describe '.cancel_merge_train' do
    subject { described_class.cancel_merge_train(noteable, project, author, reason: reason) }

    let(:noteable) { create(:merge_request, :on_train, source_project: project, target_project: project) }
    let(:reason) { }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge train' system note" do
      expect(subject.note).to eq('removed this merge request from the merge train')
    end

    context 'when reason is specified' do
      let(:reason) { 'merge request is not mergeable' }

      it "posts the 'merge train' system note" do
        expect(subject.note).to eq('removed this merge request from the merge train because merge request is not mergeable')
      end
    end
  end
end
