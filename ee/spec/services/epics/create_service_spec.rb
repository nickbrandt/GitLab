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
end
