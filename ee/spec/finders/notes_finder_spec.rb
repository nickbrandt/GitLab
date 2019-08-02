# frozen_string_literal: true

require 'spec_helper'

describe 'EE::NotesFinder' do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :owner, group: group, user: create(:user)).user }
  let(:epic) { create(:epic, :opened, author: user, group: group) }
  let!(:note) { create(:note_on_epic, noteable: epic) }

  before do
    stub_licensed_features(epics: true)
  end

  describe '#target' do
    subject { NotesFinder.new(user, { target_id: epic.id, target_type: 'epic', group_id: group.id }).target }

    it 'returns an epic as expected' do
      expect(subject).to eq(epic)
    end
  end

  describe '#execute' do
    context 'when using epics' do
      subject { NotesFinder.new(user, { target_id: epic.id, target_type: 'epic', group_id: group.id }).execute }

      it 'returns an epic as expected' do
        expect(subject).to eq([note])
      end
    end

    context 'when using an explicit epic target' do
      subject { NotesFinder.new(user, { target: epic }).execute }

      it 'returns the expected notes' do
        expect(subject).to eq([note])
      end
    end
  end
end
