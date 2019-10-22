# frozen_string_literal: true

require 'spec_helper'

describe ZoomNotesService do
  describe '#execute' do
    let(:issue) { OpenStruct.new(zoom_meetings: zoom_meetings) }
    let(:project) { Object.new }
    let(:user) { Object.new }
    let(:added_zoom_meeting) { OpenStruct.new(issue_status: ZoomMeeting.issue_statuses[:added]) }
    let(:removed_zoom_meeting) { OpenStruct.new(issue_status: ZoomMeeting.issue_statuses[:removed]) }
    let(:old_zoom_meetings) { [] }
    let(:zoom_meetings) { [] }

    subject { described_class.new(issue, project, user, old_zoom_meetings) }

    shared_examples 'no notifications' do
      it "doesn't create notifications" do
        expect(SystemNoteService).not_to receive(:zoom_link_added)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
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
    end


    context 'when old_zoom_meetings is empty and zoom_meetings contains an added zoom_meeting' do
      let(:old_zoom_meetings) { [] }
      let(:zoom_meetings) { [added_zoom_meeting] }

      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    context 'when the zoom link has been added' do
      let(:old_zoom_meetings) { [removed_zoom_meeting] }
      let(:zoom_meetings) { [removed_zoom_meeting, added_zoom_meeting] }

      it 'creates a zoom_link_added notification' do
        expect(SystemNoteService).to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).not_to receive(:zoom_link_removed)

        subject.execute
      end
    end

    context 'when the zoom link has been removed from zoom_meetings' do
      let(:old_zoom_meetings) { [added_zoom_meeting] }
      let(:zoom_meetings) { [removed_zoom_meeting] }

      it 'creates a zoom_link_removed notification' do
        expect(SystemNoteService).not_to receive(:zoom_link_added).with(issue, project, user)
        expect(SystemNoteService).to receive(:zoom_link_removed)

        subject.execute
      end
    end
  end
end
