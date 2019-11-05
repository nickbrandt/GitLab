# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::Pager do
  let(:relation) { Project.all }
  let(:request) { double('request', page: page) }
  let(:page) { double('page', per_page: 20, column: :id, last_value: 10) }

  describe '#paginate' do
    subject { described_class.new(request).paginate(relation) }

    it 'applies a limit' do
      allow(relation).to receive(:order).and_return(relation)
      expect(relation).to receive(:limit).with(page.per_page).and_call_original

      subject
    end

    it 'sorts by pagination order' do
      allow(relation).to receive(:limit).and_return(relation)
      expect(relation).to receive(:reorder).with(page.column => :asc).and_call_original

      subject
    end

    context 'without paging information' do
      let(:page) { double('page', per_page: 20, column: :id, last_value: nil) }

      it 'considers this the first page and does not apply any filter' do
        allow(relation).to receive(:limit).and_return(relation)

        expect(relation).not_to receive(:where)

        subject
      end
    end

    it 'applies a filter based on the paging information' do
      allow(relation).to receive(:limit).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)

      expect(relation).to receive(:where).with('id > ?', 10).and_call_original

      subject
    end

    it 'adds limit, order,where to the query' do
      expect(subject.relation).to eq(Project.where('id > ?', page.last_value).limit(page.per_page).order(id: :asc))
    end

    it 'passes through the page information' do
      expect(subject.page).to eq(page)
    end
  end
end
