# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectRegistry, :geo do
  describe 'relationships' do
    it { is_expected.to belong_to(:lfs_object).class_name('LfsObject') }
  end

  it_behaves_like 'a BulkInsertSafe model', Geo::LfsObjectRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_lfs_object_registry, 10) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe '.insert_for_model_ids' do
    it 'returns an array with the primary key values for all inserted records' do
      ids = described_class.insert_for_model_ids([1])

      expect(ids).to contain_exactly(a_kind_of(Integer))
    end

    context 'when duplicate items are to be inserted' do
      it 'does not raise an error' do
        registry = create(:geo_lfs_object_registry)

        expect { described_class.insert_for_model_ids([registry.lfs_object_id]) }
          .not_to raise_error
      end
    end
  end
end
