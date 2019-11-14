# frozen_string_literal: true

require 'spec_helper'

describe Notes::PostProcessService do
  describe '#execute' do
    context 'when the noteable is a design' do
      let_it_be(:noteable) { create(:design, :with_file) }
      let_it_be(:discussion_note) { create_note }

      subject { described_class.new(note).execute }

      def create_note(in_reply_to: nil)
        create(:diff_note_on_design, noteable: noteable, project: noteable.project, in_reply_to: in_reply_to)
      end

      context 'when the note is the start of a new discussion' do
        let(:note) { discussion_note }

        it 'creates a new system note' do
          expect { subject }.to change { Note.system.count }.by(1)
        end
      end

      context 'when the note is a reply within a discussion' do
        let_it_be(:note) { create_note(in_reply_to: discussion_note) }

        it 'does not create a new system note' do
          expect { subject }.not_to change { Note.system.count }
        end
      end
    end
  end
end
