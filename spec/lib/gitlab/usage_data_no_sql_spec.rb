# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataNoSql do
  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  describe '.count' do
    it 'returns -2 uncomputed metric' do
      expect(described_class.count(User)).to eq(-2)
    end
  end

  describe '.distinct_count' do
    it 'returns -2 uncomputed metric' do
      expect(described_class.distinct_count(User)).to eq(-2)
    end
  end

  describe '.estimate_batch_distinct_count' do
    it 'returns -2 uncomputed metric' do
      expect(described_class.distinct_count(User)).to eq(-2)
    end
  end
end
