# frozen_string_literal: true

require 'spec_helper'

describe Epics::CreateService do
  let(:group) { create(:group, :internal)}
  let(:user) { create(:user) }
  let!(:parent_epic) { create(:epic, group: group) }
  let(:params) { { title: 'new epic', description: 'epic description', parent_id: parent_epic.id } }

  subject { described_class.new(group, user, params).execute }

  describe '#execute' do
    it 'creates one epic correctly' do
      allow(NewEpicWorker).to receive(:perform_async)

      expect { subject }.to change { Epic.count }.by(1)

      epic = Epic.last
      expect(epic).to be_persisted
      expect(epic.title).to eq('new epic')
      expect(epic.description).to eq('epic description')
      expect(epic.parent).to eq(parent_epic)
      expect(epic.relative_position).not_to be_nil
      expect(NewEpicWorker).to have_received(:perform_async).with(epic.id, user.id)
    end
  end

  context 'handling fixed dates' do
    it 'sets the fixed date correctly' do
      date = Date.new(2019, 10, 10)
      params[:start_date_fixed] = date
      params[:start_date_is_fixed] = true

      subject

      epic = Epic.last
      expect(epic.start_date).to eq(date)
      expect(epic.start_date_fixed).to eq(date)
      expect(epic.start_date_is_fixed).to be_truthy
    end
  end

  context 'after_save callback to store_mentions' do
    # let(:user2) { create(:user) }
    # let(:epic) { create(:epic, group: group, description: "mentioning: #{user2.to_reference}") }
    let(:labels) { create_pair(:group_label, group: group) }

    context 'when mentionable attributes change' do
      let(:params) { { title: 'Title', description: "Description with #{user.to_reference}" } }

      it 'saves mentions' do
        expect_next_instance_of(Epic) do |instance|
          expect(instance).to receive(:store_mentions!).and_call_original
        end
        expect(subject.user_mentions.count).to eq 1
      end
    end

    context 'when save fails' do
      let(:params) { { title: '', label_ids: labels.map(&:id) } }

      it 'does not call store_mentions' do
        expect_next_instance_of(Epic) do |instance|
          expect(instance).not_to receive(:store_mentions!).and_call_original
        end
        expect(subject.valid?).to be false
        expect(subject.user_mentions.count).to eq 0
      end
    end
  end
end
