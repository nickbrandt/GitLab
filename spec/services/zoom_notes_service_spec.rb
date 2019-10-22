# frozen_string_literal: true

require 'spec_helper'

describe ZoomNotesService do
  describe '#execute' do
    let(:issue) { OpenStruct.new(zoom_meetings: zoom_meetings) }
    let(:project) { Object.new }
    let(:user) { Object.new }
    let(:added_zoom_meeting) { OpenStruct.new(issue_status: "added") }
    let(:removed_zoom_meeting) { OpenStruct.new(issue_status: "removed") }
    let(:old_zoom_meetings) { [] }
    let(:zoom_meetings) { [] }

    subject { described_class.new(issue, project, user, zoom_meetings: old_zoom_meetings) }

    shared_examples 'no notifications' do
      it "doesn't create notifications" do
        expect(SystemNoteService).not_to receive(:zoom_link_added)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    shared_examples 'added notification' do
      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    shared_examples 'removed notification' do
      it 'creates a zoom_link_removed notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).to receive(:zoom_link_removed)

        subject.execute
      end
    end

    context 'when zoom_meetings is not in old_associations' do
      subject { described_class.new(issue, project, user, {}) }

      context 'when zoom_meetings is empty' do
        it_behaves_like 'no notifications'
      end

      context 'when zoom_meetings has "added" meeting' do
        let(:zoom_meetings) { [added_zoom_meeting] }

        it_behaves_like 'added notification'
      end

      context 'when zoom_meetings has "removed" meeting' do
        let(:zoom_meetings) { [removed_zoom_meeting] }

        it_behaves_like 'removed notification'
      end
    end

    context 'when zoom_meetings == old_zoom_meetings' do
      context 'when both are empty' do
        it_behaves_like 'no notifications'
      end

      context 'when both are removed' do
        let(:old_zoom_meetings) { [removed_zoom_meeting] }
        let(:zoom_meetings) { old_zoom_meetings }

        it_behaves_like 'no notifications'
      end

      context 'when both are added' do
        let(:old_zoom_meetings) { [added_zoom_meeting] }
        let(:zoom_meetings) { old_zoom_meetings }

        it_behaves_like 'no notifications'
      end
    end

    context 'when old_zoom_meetings is empty and zoom_meetings contains an "added" zoom_meeting' do
      let(:old_zoom_meetings) { [] }
      let(:zoom_meetings) { [added_zoom_meeting] }

      it_behaves_like 'added notification'
    end

    context 'when a "added" meeting is added to a list of "removed" meetings' do
      let(:old_zoom_meetings) { [removed_zoom_meeting] }
      let(:zoom_meetings) { [removed_zoom_meeting, added_zoom_meeting] }

      it_behaves_like 'added notification'
    end

    context 'when zoom_meetings no longer has an "added" zoom meeting' do
      let(:old_zoom_meetings) { [added_zoom_meeting] }
      let(:zoom_meetings) { [removed_zoom_meeting] }

      it_behaves_like 'removed notification'
    end
  end
end
