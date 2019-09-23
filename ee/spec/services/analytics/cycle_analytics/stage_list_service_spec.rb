# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::StageListService do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  subject { described_class.new(parent: group, current_user: user) }

  context 'succeeds' do
    let(:stages) { subject.execute.payload[:stages] }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      group.add_reporter(user)
    end

    it 'returns only the default stages' do
      expect(stages.size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
    end

    it 'provides the default stages as non-persisted objects' do
      stage_ids = stages.map(&:id)
      expect(stage_ids.all?(&:nil?)).to eq(true)
    end
  end

  it 'returns forbidden response' do
    result = subject.execute

    expect(result).to be_error
    expect(result.http_status).to eq(:forbidden)
  end
end
