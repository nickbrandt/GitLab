# frozen_string_literal: true

require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  context 'on issuable update' do
    it_behaves_like 'system note creation', { weight: 5 }, 'changed weight to **5**'

    context 'when issuable is an epic' do
      let(:timestamp) { Time.now }
      let(:issuable) { create(:epic, end_date: timestamp) }

      subject { described_class.new(nil, user).execute(issuable, old_labels: []) }

      before do
        issuable.assign_attributes(start_date: timestamp, end_date: nil)
        issuable.save
      end

      it 'creates 2 system notes with the correct content' do
        expect { subject }.to change { Note.count }.from(0).to(2)

        expect(Note.first.note).to match("changed start date to #{timestamp.strftime('%b %-d, %Y')}")
        expect(Note.second.note).to match('removed the finish date')
      end
    end
  end

  context 'on issuable create' do
    let(:issuable) { build(:issue) }

    subject { described_class.new(project, user).execute(issuable, old_labels: [], is_update: false) }

    before do
      issuable.weight = 5
      issuable.save
    end

    it 'creates a system note for weight' do
      expect { subject }.to change { issuable.notes.count }.from(0).to(1)
      expect(issuable.notes.last.note).to match('changed weight')
    end

    context 'when resource weight event tracking is enabled' do
      before do
        stub_feature_flags(track_resource_weight_change_events: true)
      end

      it 'creates a resource weight event' do
        subject

        note = issuable.notes.last
        event = issuable.resource_weight_events.last

        expect(event.weight).to eq(5)
        expect(event.created_at).to eq(note.created_at)
      end
    end

    context 'when resource weight event tracking is disabled' do
      before do
        stub_feature_flags(track_resource_weight_change_events: false)
      end

      it 'does not created a resource weight event' do
        expect { subject }.not_to change { ResourceWeightEvent.count }
      end
    end
  end
end
