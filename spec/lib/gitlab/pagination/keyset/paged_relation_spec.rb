# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::PagedRelation do
  before_all do
    create_list(:project, 10)
  end

  let(:relation) { Project.all.limit(page.per_page) }
  let(:page) { double('page', column: :id, per_page: 5) }

  describe '#next_page' do
    subject { described_class.new(relation, page).next_page }

    it 'retrieves the last record on the page to establish a last_value for the page' do
      next_page = subject

      expect(next_page.last_value).to eq(relation.last.id)
      expect(next_page.column).to eq(page.column)
      expect(next_page.per_page).to eq(page.per_page)
    end

    context 'when the page is empty' do
      let(:relation) { Project.none }

      it 'returns a Page indicating its emptiness' do
        next_page = subject

        expect(next_page.empty?).to be_truthy
        expect(next_page.column).to eq(page.column)
        expect(next_page.per_page).to eq(page.per_page)
      end
    end
  end
end
