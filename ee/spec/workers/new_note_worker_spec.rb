# frozen_string_literal: true

require 'spec_helper'

describe NewNoteWorker do
  context 'when skip_notification' do
    it 'does not create a new note notification' do
      note = create(:note, :with_review)

      expect_any_instance_of(NotificationService).not_to receive(:new_note)

      subject.perform(note.id)
    end
  end
end
