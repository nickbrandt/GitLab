# frozen_string_literal: true

require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  context 'on issuable update' do
    context 'when weight is changed' do
      before do
        issuable.update!(weight: 5)
      end

      it 'creates a resource label event' do
        described_class.new(project, user).execute(issuable, old_labels: [])
        event = issuable.reload.resource_weight_events.last

        expect(event).not_to be_nil
        expect(event.weight).to eq 5
        expect(event.user_id).to eq user.id
      end
    end

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

    it 'does not create a common system note for weight' do
      expect { subject }.not_to change { issuable.notes.count }
    end

    context 'when resource weight event tracking is enabled' do
      before do
        stub_feature_flags(track_issue_weight_change_events: true)
      end

      it 'creates a resource weight event' do
        subject

        event = issuable.resource_weight_events.last

        expect(event.weight).to eq(5)
        expect(event.user_id).to eq(user.id)
      end

      it 'does not create a system note' do
        expect { subject }.not_to change { Note.count }
      end
    end

    context 'when resource weight event tracking is disabled' do
      before do
        stub_feature_flags(track_issue_weight_change_events: false)
      end

      it 'does not created a resource weight event' do
        expect { subject }.not_to change { ResourceWeightEvent.count }
      end

      it 'does create a system note' do
        expect { subject }.to change { Note.count }.from(0).to(1)

        expect(Note.first.note).to eq('changed weight to **5**')
      end
    end
  end
end
