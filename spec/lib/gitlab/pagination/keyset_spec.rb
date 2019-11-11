# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset do
  describe '.paginate' do
    subject { described_class.paginate(request_context, relation) }

    let(:request_context) { double }
    let(:relation) { double }
    let(:pager) { double }
    let(:result) { double }

    it 'uses Pager to paginate the relation' do
      expect(Gitlab::Pagination::Keyset::Pager).to receive(:new).with(request_context).and_return(pager)
      expect(pager).to receive(:paginate).with(relation).and_return(result)

      expect(subject).to eq(result)
    end
  end
end
