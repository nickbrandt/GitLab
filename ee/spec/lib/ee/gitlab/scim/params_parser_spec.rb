# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Scim::ParamsParser do
  describe '#result' do
    it 'returns the correct filter attributes' do
      filter = 'id eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).result).to eq(extern_uid: '6ba81b08-77da')
    end

    it 'returns an empty hash for the wrong filter' do
      filter = 'blah eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).result).to eq({})
    end

    it 'returns the correct operation attributes' do
      operations = [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }]

      expect(described_class.new(Operations: operations).result).to eq(active: false)
    end

    it 'returns an empty hash for the wrong operations' do
      operations = [{ 'op': 'Replace', 'path': 'test', 'value': 'False' }]

      expect(described_class.new(Operations: operations).result).to eq({})
    end

    it 'returns a parsed hash for POST params' do
      params = {
        externalId: 'test',
        active: nil,
        userName: 'username',
        emails: [
          { primary: nil, type: 'work', value: 'work@example.com' },
          { primary: nil, type: 'home', value: 'home@example.com' }
        ],
        name: { formatted: 'Test Name', familyName: 'Name', givenName: 'Test' },
        extra: true
      }

      expect(described_class.new(params).result).to eq(email: 'work@example.com',
                                                       extern_uid: 'test',
                                                       name: 'Test Name',
                                                       username: 'username')
    end
  end

  describe '#deprovision_user?' do
    it 'returns true when deprovisioning' do
      operations = [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }]

      expect(described_class.new(Operations: operations).deprovision_user?).to be true
    end

    it 'returns false when not deprovisioning' do
      operations = [{ 'op': 'Replace', 'path': 'active', 'value': 'True' }]

      expect(described_class.new(Operations: operations).deprovision_user?).to be false
    end
  end
end
