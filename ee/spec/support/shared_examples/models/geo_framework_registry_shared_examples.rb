# frozen_string_literal: true

shared_examples 'a Geo framework registry' do
  let(:registry_class_factory) { described_class.underscore.tr('/', '_').sub('geo_', '').to_sym }

  let!(:failed_item1) { create(registry_class_factory, :failed) }
  let!(:failed_item2) { create(registry_class_factory, :failed) }
  let!(:unsynced_item1) { create(registry_class_factory) }
  let!(:unsynced_item2) { create(registry_class_factory) }

  describe '.find_unsynced_registries' do
    it 'returns unsynced items' do
      result = described_class.find_unsynced_registries(batch_size: 10)

      expect(result).to include(unsynced_item1, unsynced_item2)
    end

    it 'returns unsynced items except some specific item ID' do
      except_id = unsynced_item1.model_record_id

      result = described_class.find_unsynced_registries(batch_size: 10, except_ids: [except_id])

      expect(result).to include(unsynced_item2)
      expect(result).not_to include(unsynced_item1)
    end
  end

  describe '.find_failed_registries' do
    it 'returns failed items' do
      result = described_class.find_failed_registries(batch_size: 10)

      expect(result).to include(failed_item1, failed_item2)
    end

    it 'returns failed items except some specific item ID' do
      except_id = failed_item1.model_record_id

      result = described_class.find_failed_registries(batch_size: 10, except_ids: [except_id])

      expect(result).to include(failed_item2)
      expect(result).not_to include(failed_item1)
    end
  end
end
