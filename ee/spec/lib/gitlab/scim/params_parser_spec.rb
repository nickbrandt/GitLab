# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Scim::ParamsParser do
  describe '#to_hash' do
    it 'returns the correct filter attributes' do
      filter = 'id eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).to_hash).to eq(extern_uid: '6ba81b08-77da')
    end

    it 'returns an empty hash for the wrong filter' do
      filter = 'blah eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).to_hash).to eq({})
    end

    it 'returns the correct operation attributes' do
      operations = [{ "op": "Replace", "path": "active", "value": "False" }]

      expect(described_class.new(operations: operations).to_hash).to eq(active: false)
    end

    it 'returns an empty hash for the wrong operations' do
      operations = [{ "op": "Replace", "path": "test", "value": "False" }]

      expect(described_class.new(operations: operations).to_hash).to eq({})
    end
  end

  describe '#deprovision_user?' do
    it 'returns true when deprovisioning' do
      operations = [{ "op": "Replace", "path": "active", "value": "False" }]

      expect(described_class.new(operations: operations).deprovision_user?).to be true
    end

    it 'returns false when not deprovisioning' do
      operations = [{ "op": "Replace", "path": "active", "value": "True" }]

      expect(described_class.new(operations: operations).deprovision_user?).to be false
    end
  end
end
