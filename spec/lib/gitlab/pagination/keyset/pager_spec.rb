# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::Pager do
  let(:relation) { Project.all.order(id: :asc) }
  let(:request) { double('request', page: page, apply_headers: nil) }
  let(:page) { Gitlab::Pagination::Keyset::Page.new(order_by: { id: :asc }, per_page: 20) }
  let(:next_page) { double('next page') }

  before_all do
    create_list(:project, 25)
  end

  describe '#paginate' do
    subject { described_class.new(request).paginate(relation) }

    it 'loads the result relation only once' do
      expect do
        subject
      end.not_to exceed_query_limit(1)
    end

    it 'passes information about next page to request' do
      lower_bounds = relation.limit(20).last.slice(:id)
      expect(page).to receive(:next).with(lower_bounds, false).and_return(next_page)
      expect(request).to receive(:apply_headers).with(next_page)

      subject
    end

    context 'while retrieving the last page' do
      let(:relation) { Project.where('id >= ?', Project.maximum(:id) - 10).order(id: :asc) }

      it 'indicates this is the last page' do
        expect(request).to receive(:apply_headers) do |next_page|
          expect(next_page.end_reached?).to be_truthy
        end

        subject
      end
    end

    it 'returns an array with the loaded records' do
      expect(subject).to eq(relation.limit(20).to_a)
    end
  end
end
