# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Scim::ParamsParser do
  describe '#filter_params' do
    it 'returns the correct filter attributes' do
      filter = 'id eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).filter_params).to eq(extern_uid: '6ba81b08-77da')
    end

    it 'returns an empty hash for the wrong filter' do
      filter = 'blah eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).filter_params).to eq({})
    end
  end

  describe '#filter_operator' do
    it 'returns the operator as a symbol' do
      parser = described_class.new(filter: 'id eq 1')

      expect(parser.filter_operator).to eq(:eq)
    end

    it 'returns nil if the filter is invalid' do
      parser = described_class.new(filter: 'this eq that')

      expect(parser.filter_operator).to eq(nil)
    end
  end

  describe '#update_params' do
    it 'returns the correct operation attributes' do
      operations = [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }]

      expect(described_class.new(Operations: operations).update_params).to eq(active: false)
    end

    it 'returns an empty hash for the wrong operations' do
      operations = [{ 'op': 'Replace', 'path': 'test', 'value': 'False' }]

      expect(described_class.new(Operations: operations).update_params).to eq({})
    end

    it 'can update name from displayName' do
      operations = [{ 'op': 'Replace', 'path': 'displayName', 'value': 'My Name Is' }]

      expect(described_class.new(Operations: operations).update_params).to include(name: 'My Name Is')
    end
  end

  describe '#post_params' do
    it 'returns a parsed hash for POST params' do
      params = {
        externalId: 'test',
        active: nil,
        userName: 'username',
        emails: [
          { primary: nil, type: 'work', value: 'work@example.com' },
          { primary: nil, type: 'home', value: 'home@example.com' }
        ],
        name: { formatted: 'Test A. Name', familyName: 'Name', givenName: 'Test' },
        displayName: 'Test A',
        extra: true
      }

      expect(described_class.new(params).post_params).to eq(email: 'work@example.com',
                                                            extern_uid: 'test',
                                                            name: 'Test A. Name',
                                                            username: 'username')
    end

    it 'can construct a name from givenName and familyName' do
      params = { name: { givenName: 'Fred', familyName: 'Nurk' } }

      expect(described_class.new(params).post_params).to include(name: 'Fred Nurk')
    end

    it 'falls back to displayName when other names are missing' do
      params = { displayName: 'My Name' }

      expect(described_class.new(params).post_params).to include(name: 'My Name')
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
