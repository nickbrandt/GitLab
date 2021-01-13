# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreamErrorsSerializer do
  let_it_be(:group) { create(:group) }
  let_it_be(:value_stream) { create(:cycle_analytics_group_value_stream, name: 'name', group: group) }

  subject { described_class.new(value_stream).as_json }

  it 'serializes error on value stream object' do
    value_stream.name = ''

    value_stream.validate

    expect(subject[:name]).not_to be_empty
  end

  context 'when nested value stream stages are given' do
    let(:invalid_stage) { build(:cycle_analytics_group_stage, name: '', group: group) }
    let(:valid_stage) { build(:cycle_analytics_group_stage, group: group) }

    before do
      value_stream.stages << invalid_stage
      value_stream.stages << valid_stage
    end

    it 'serializes error on value stream object' do
      value_stream.validate

      stage = subject[:stages].first
      expect(stage[:errors]).not_to be_empty
    end
  end
end
