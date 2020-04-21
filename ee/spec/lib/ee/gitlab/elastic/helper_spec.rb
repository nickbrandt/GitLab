# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elastic::Helper do
  subject(:helper) { described_class.default }

  shared_context 'with an existing index' do
    before do
      helper.create_empty_index
    end
  end

  after do
    helper.delete_index
  end

  describe '.new' do
    it 'has the proper default values' do
      expect(helper).to have_attributes(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        index_name: ::Elastic::Latest::Config.index_name)
    end

    context 'with a custom `index_name`' do
      let(:index_name) { 'custom-index-name' }

      subject(:helper) { described_class.new(index_name: index_name) }

      it 'has the proper `index_name`' do
        expect(helper).to have_attributes(index_name: index_name)
      end
    end
  end

  describe '#create_empty_index' do
    context 'without an existing index' do
      it 'creates the index' do
        helper.create_empty_index

        expect(helper.index_exists?).to eq(true)
      end
    end

    context 'when there is an index' do
      include_context 'with an existing index'

      it 'raises an error' do
        expect { helper.create_empty_index }.to raise_error
      end
    end
  end

  describe '#delete_index' do
    subject { helper.delete_index }

    context 'without an existing index' do
      it 'fails gracefully' do
        is_expected.to be_falsy
      end
    end

    context 'when there is an index' do
      include_context 'with an existing index'

      it { is_expected.to be_truthy }
    end
  end

  describe '#index_exists?' do
    subject { helper.index_exists? }

    context 'without an existing index' do
      it { is_expected.to be_falsy }
    end

    context 'when there is an index' do
      include_context 'with an existing index'

      it { is_expected.to be_truthy }
    end
  end
end
