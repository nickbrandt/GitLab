# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::Pager do
  let(:relation) { Project.all.order(id: :asc) }
  let(:request) { double('request', page: page, apply_headers: nil) }
  let(:page) { double('page', per_page: 20, order_by: { id: :asc }, lower_bounds: nil, next: nil) }
  let(:next_page) { double('next page') }

  before_all do
    create_list(:project, 5)
  end

  describe '#paginate' do
    subject { described_class.new(request).paginate(relation) }

    it 'applies a limit' do
      expect(relation).to receive(:limit).with(page.per_page).and_call_original

      subject
    end

    it 'loads the result relation only once' do
      expect do
        subject
      end.not_to exceed_query_limit(1)
    end

    it 'passes information about next page to request' do
      lower_bounds = relation.last.slice(:id)
      expect(page).to receive(:next).with(lower_bounds, false).and_return(next_page)
      expect(request).to receive(:apply_headers).with(next_page)

      subject
    end

    it 'returns the limited relation' do
      expect(subject).to eq(relation.limit(20))
    end
  end
end
