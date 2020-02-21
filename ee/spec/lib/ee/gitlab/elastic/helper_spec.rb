# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Elastic::Helper do
  describe '.index_exists' do
    it 'returns correct values' do
      described_class.create_empty_index

      expect(described_class.index_exists?).to eq(true)

      described_class.delete_index

      expect(described_class.index_exists?).to eq(false)
    end
  end
end
