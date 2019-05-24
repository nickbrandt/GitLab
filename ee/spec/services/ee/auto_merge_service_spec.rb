# frozen_string_literal: true

require 'spec_helper'

describe AutoMergeService do
  describe '.all_strategies' do
    subject { described_class.all_strategies }

    it 'includes all strategies' do
      is_expected.to include(AutoMergeService::STRATEGY_MERGE_TRAIN)
    end
  end
end
