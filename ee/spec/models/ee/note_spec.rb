# frozen_string_literal: true

require 'spec_helper'

describe Note do
  include ::EE::GeoHelpers

  describe 'associations' do
    it { is_expected.to belong_to(:review).inverse_of(:notes) }
  end

  describe 'scopes' do
    describe '.with_suggestions' do
      it 'returns the correct note' do
        note_with_suggestion = create(:note, suggestions: [create(:suggestion)])
        note_without_suggestion = create(:note)

        expect(described_class.with_suggestions).to include(note_with_suggestion)
        expect(described_class.with_suggestions).not_to include(note_without_suggestion)
      end
    end
  end

  describe 'callbacks' do
    describe '#notify_after_create' do
      it 'calls #after_note_created on the noteable' do
        note = build(:note)

        expect(note).to receive(:notify_after_create).and_call_original
        expect(note.noteable).to receive(:after_note_created).with(note)

        note.save!
      end
    end

    describe '#notify_after_destroy' do
      it 'calls #after_note_destroyed on the noteable' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note.noteable).to receive(:after_note_destroyed).with(note)

        note.destroy
      end

      it 'does not error if noteable is nil' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note).to receive(:noteable).at_least(:once).and_return(nil)
        expect { note.destroy }.not_to raise_error
      end
    end
  end

  context 'object storage with background upload' do
    before do
      stub_uploads_object_storage(AttachmentUploader, background_upload: true)
    end

    context 'when running in a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
      end

      it 'creates a Geo deleted log event for attachment' do
        Sidekiq::Testing.inline! do
          expect do
            create(:note, :with_attachment)
          end.to change(Geo::UploadDeletedEvent, :count).by(1)
        end
      end
    end
  end

  describe '#resource_parent' do
    it 'returns group for epic notes' do
      group = create(:group)
      note = create(:note_on_epic, noteable: create(:epic, group: group))

      expect(note.resource_parent).to eq(group)
    end
  end

  describe '#for_design' do
    it 'is true when the noteable is a design' do
      note = build(:note, noteable: build(:design))

      expect(note).to be_for_design
    end
  end

  describe '.by_humans' do
    it 'return human notes only' do
      user_note = create(:note)
      create(:system_note)
      create(:note, author: create(:user, :bot))

      expect(described_class.by_humans).to match_array([user_note])
    end
  end
end
