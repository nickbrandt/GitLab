# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Scim::ParamsParser do
  describe '#to_hash' do
    it 'returns the correct filter attributes' do
      filter = 'id eq "6ba81b08-77da"'

      expect(described_class.new(filter: filter).to_hash).to eq(extern_uid: '6ba81b08-77da')
    end
  end
end
