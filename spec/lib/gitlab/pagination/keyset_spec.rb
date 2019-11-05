# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset do
  describe '.paginate' do
    subject { described_class.paginate(request_context, relation) }

    let(:request_context) { instance_double(Gitlab::Pagination::Keyset::RequestContext, apply_headers: nil) }
    let(:pager) { instance_double(Gitlab::Pagination::Keyset::Pager, paginate: paged_relation)}
    let(:relation) { double('relation') }
    let(:paged_relation) { double('paged relation', relation: double) }

    before do
      allow(Gitlab::Pagination::Keyset::Pager).to receive(:new).with(request_context).and_return(pager)
    end

    it 'applies headers' do
      expect(request_context).to receive(:apply_headers).with(paged_relation)

      subject
    end

    it 'returns the paginated relation' do
      expect(subject).to eq(paged_relation.relation)
    end

    it 'paginates the relation' do
      expect(pager).to receive(:paginate).with(relation).and_return(paged_relation)

      subject
    end
  end
end
