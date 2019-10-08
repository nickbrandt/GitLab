# frozen_string_literal: true

require 'spec_helper'

describe SystemNoteService do
  include ProjectForksHelper
  include Gitlab::Routing
  include RepoHelpers
  include DesignManagementTestHelpers

  set(:group)    { create(:group) }
  set(:project)  { create(:project, :repository, group: group) }
  set(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic, group: group) }

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
    subject { described_class.design_version_added(version) }

    # default (valid) parameters:
    set(:issue) { create(:issue) }
    let(:n_designs) { 3 }
    let(:designs) { create_list(:design, n_designs, issue: issue) }
    let(:user) { build(:user) }
    let(:version) do
      create(:design_version, issue: issue, designs: designs)
    end

    before do
      # Avoid needing to call into gitaly
      allow(version).to receive(:author).and_return(user)
    end

    context 'with one kind of event' do
      before do
        DesignManagement::Action
          .where(design: designs).update_all(event: :modification)
      end

      it 'makes just one note' do
        expect(subject).to contain_exactly(Note)
      end

      it 'adds a new system note' do
        expect { subject }.to change { Note.system.count }.by(1)
      end
    end

    context 'with a mixture of events' do
      let(:n_designs) { DesignManagement::Action.events.size }

      before do
        designs.each_with_index do |design, i|
          design.actions.update_all(event: i)
        end
      end

      it 'makes one note for each kind of event' do
        expect(subject).to have_attributes(size: n_designs)
      end

      it 'adds a system note for each kind of event' do
        expect { subject }.to change { Note.system.count }.by(n_designs)
      end
    end

    context 'it succeeds' do
      where(:action, :icon, :human_description) do
        [
          [:creation,     'designs_added',    'added'],
          [:modification, 'designs_modified', 'updated'],
          [:deletion,     'designs_removed',  'removed']
        ]
      end

      with_them do
        before do
          version.actions.update_all(event: action)
        end

        let(:anchor_tag) { %r{ <a[^>]*>#{link}</a>} }
        let(:href) { described_class.send(:design_version_path, version) }
        let(:link) { "#{n_designs} designs" }

        subject(:note) { described_class.design_version_added(version).first }

        it 'has the correct data' do
          expect(note)
            .to be_system
            .and have_attributes(
              system_note_metadata: have_attributes(action: icon),
              note: include(human_description)
                      .and(include link)
                      .and(include href),
              note_html: a_string_matching(anchor_tag)
            )
        end
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

    it_behaves_like 'a system note', exclude_project: true do
      let(:action) { 'unapproved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "unapproved this merge request"
      end
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

    let(:pipeline) { build(:ci_pipeline_without_jobs) }

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
