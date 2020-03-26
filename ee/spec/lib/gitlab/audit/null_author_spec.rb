# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Audit::NullAuthor do
  describe '.for' do
    it 'returns an DeletedAuthor' do
      expect(described_class.for(666, 'Old Hat')).to be_a(Gitlab::Audit::DeletedAuthor)
    end

    it 'returns an UnauthenticatedAuthor when id equals -1', :aggregate_failures do
      expect(described_class.for(-1, 'Frank')).to be_a(Gitlab::Audit::UnauthenticatedAuthor)
      expect(described_class.for(-1, 'Frank')).to have_attributes(id: -1, name: 'Frank')
    end
  end
end
