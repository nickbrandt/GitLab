# frozen_string_literal: true

require 'spec_helper'

describe SystemNoteService do
  include ProjectForksHelper
  include Gitlab::Routing
  include RepoHelpers
  include DesignManagementTestHelpers

  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }
  let_it_be(:noteable) { create(:issue, project: project) }
  let_it_be(:issue)    { noteable }
  let_it_be(:epic)     { create(:epic, group: group) }

  describe '.relate_issue' do
    let(:noteable_ref) { double }
    let(:noteable) { double }

    before do
      allow(noteable).to receive(:project).and_return(double)
    end

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:relate_issue).with(noteable_ref)
      end

      described_class.relate_issue(noteable, noteable_ref, double)
    end
  end

  describe '.unrelate_issue' do
    let(:noteable_ref) { double }
    let(:noteable) { double }

    before do
      allow(noteable).to receive(:project).and_return(double)
    end

    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:unrelate_issue).with(noteable_ref)
      end

      described_class.unrelate_issue(noteable, noteable_ref, double)
    end
  end

  describe '.design_version_added' do
    let(:version) { create(:design_version) }

    it 'calls DesignManagementService' do
      expect_next_instance_of(EE::SystemNotes::DesignManagementService) do |service|
        expect(service).to receive(:design_version_added).with(version)
      end

      described_class.design_version_added(version)
    end
  end

  describe '.design_discussion_added' do
    let(:discussion_note) { create(:diff_note_on_design) }

    it 'calls DesignManagementService' do
      expect_next_instance_of(EE::SystemNotes::DesignManagementService) do |service|
        expect(service).to receive(:design_discussion_added).with(discussion_note)
      end

      described_class.design_discussion_added(discussion_note)
    end
  end

  describe '.approve_mr' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:approve_mr)
      end

      described_class.approve_mr(noteable, author)
    end
  end

  describe '.unapprove_mr' do
    it 'calls MergeRequestsService' do
      expect_next_instance_of(::SystemNotes::MergeRequestsService) do |service|
        expect(service).to receive(:unapprove_mr)
      end

      described_class.unapprove_mr(noteable, author)
    end
  end

  describe '.change_weight_note' do
    it 'calls IssuableService' do
      expect_next_instance_of(::SystemNotes::IssuablesService) do |service|
        expect(service).to receive(:change_weight_note)
      end

      described_class.change_weight_note(noteable, project, author)
    end
  end

  describe '.change_epic_date_note' do
    let(:timestamp) { Time.now }

    context 'when start date was changed' do
      let(:noteable) { create(:epic) }

      subject { described_class.change_epic_date_note(noteable, author, 'start date', timestamp) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed start date to #{timestamp.strftime('%b %-d, %Y')}"
      end
    end

    context 'when start date was removed' do
      let(:noteable) { create(:epic, start_date: timestamp) }

      subject { described_class.change_epic_date_note(noteable, author, 'start date', nil) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the start date'
      end
    end

    context '.issue_promoted' do
      context 'note on the epic' do
        subject { described_class.issue_promoted(epic, issue, author, direction: :from) }

        it_behaves_like 'a system note', exclude_project: true do
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

    context 'issue added to an epic' do
      subject { described_class.epic_issue(epic, issue, author, :added) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_issue_added' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("added issue #{issue.to_reference(epic.group)}")
      end
    end

    context 'issue removed from an epic' do
      subject { described_class.epic_issue(epic, issue, author, :removed) }

      it_behaves_like 'a system note', exclude_project: true do
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

    it_behaves_like 'a system note', exclude_project: true do
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

    it_behaves_like 'a system note', exclude_project: true do
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
        expect(subject.note).to eq('added this merge request to the merge train at position 2')
      end
    end
  end

  describe '.cancel_merge_train' do
    subject { described_class.cancel_merge_train(noteable, project, author) }

    let(:noteable) { create(:merge_request, :on_train, source_project: project, target_project: project) }
    let(:reason) { }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge train' system note" do
      expect(subject.note).to eq('removed this merge request from the merge train')
    end
  end

  describe '.abort_merge_train' do
    subject { described_class.abort_merge_train(noteable, project, author, 'source branch was updated') }

    let(:noteable) { create(:merge_request, :on_train, source_project: project, target_project: project) }
    let(:reason) { }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge train' system note" do
      expect(subject.note).to eq('removed this merge request from the merge train because source branch was updated')
    end
  end

  describe '.add_to_merge_train_when_pipeline_succeeds' do
    subject { described_class.add_to_merge_train_when_pipeline_succeeds(noteable, project, author, pipeline.sha) }

    let(:pipeline) { build(:ci_pipeline) }

    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'add to merge train when pipeline succeeds' system note" do
      expect(subject.note).to match(%r{enabled automatic add to merge train when the pipeline for (\w+/\w+@)?\h{40} succeeds})
    end
  end

  describe '.cancel_add_to_merge_train_when_pipeline_succeeds' do
    subject { described_class.cancel_add_to_merge_train_when_pipeline_succeeds(noteable, project, author) }

    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'add to merge train when pipeline succeeds' system note" do
      expect(subject.note).to eq 'cancelled automatic add to merge train'
    end
  end

  describe '.abort_add_to_merge_train_when_pipeline_succeeds' do
    subject { described_class.abort_add_to_merge_train_when_pipeline_succeeds(noteable, project, author, 'target branch was changed') }

    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'add to merge train when pipeline succeeds' system note" do
      expect(subject.note).to eq 'aborted automatic add to merge train because target branch was changed'
    end
  end
end
