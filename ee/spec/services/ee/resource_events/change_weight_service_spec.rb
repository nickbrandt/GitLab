# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ResourceEvents::ChangeWeightService do
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, weight: 3) }
  let(:created_at_time) { Time.new(2019, 1, 1, 12, 30, 48) }

  subject { described_class.new(issue, user, created_at_time).execute }

  before do
    ResourceWeightEvent.new(issue: issue, user: user).save!
  end

  it 'creates the expected event record' do
    expect { subject }.to change { ResourceWeightEvent.count }.by(1)

    record = ResourceWeightEvent.last
    expect_event_record(record, weight: 3, created_at: created_at_time)
  end

  context 'when weight is nil' do
    let(:issue) { create(:issue, weight: nil) }

    it 'creates an event record' do
      expect { subject }.to change { ResourceWeightEvent.count }.by(1)

      record = ResourceWeightEvent.last
      expect_event_record(record, weight: nil, created_at: created_at_time)
    end
  end

  context 'when there is no existing weight event record' do
    before do
      ResourceWeightEvent.delete_all
    end

    it 'creates the expected event records' do
      expect { subject }.to change { ResourceWeightEvent.count }.by(2)

      record = ResourceWeightEvent.first
      expect_event_record(record, weight: 3, created_at: issue.reload.updated_at)

      record = ResourceWeightEvent.last
      expect_event_record(record, weight: 3, created_at: created_at_time)
    end
  end

  def expect_event_record(record, weight:, created_at:)
    expect(record.issue).to eq(issue)
    expect(record.user).to eq(user)
    expect(record.weight).to eq(weight)
    expect(record.created_at).to eq(created_at)
  end
end
