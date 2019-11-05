# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::Page do
  describe '#per_page' do
    it 'limits to a maximum of 20 records per page' do
      per_page = described_class.new(double, per_page: 21).per_page

      expect(per_page).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    it 'uses default value when given 0' do
      per_page = described_class.new(double, per_page: 0).per_page

      expect(per_page).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    it 'uses default value when given negative values' do
      per_page = described_class.new(double, per_page: -1).per_page

      expect(per_page).to eq(described_class::DEFAULT_PAGE_SIZE)
    end
  end
end
