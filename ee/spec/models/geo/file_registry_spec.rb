require 'spec_helper'

describe Geo::FileRegistry do
  set(:failed) { create(:geo_file_registry, :failed) }
  set(:synced) { create(:geo_file_registry) }

  describe '.failed' do
    it 'returns registries in the failed state' do
      expect(described_class.failed).to match_ids(failed)
    end
  end

  describe '.synced' do
    it 'returns registries in the synced state' do
      expect(described_class.synced).to match_ids(synced)
    end
  end

  describe '.retry_due' do
    it 'returns registries in the synced state' do
      retry_yesterday = create(:geo_file_registry, retry_at: Date.yesterday)
      create(:geo_file_registry, retry_at: Date.tomorrow)

      expect(described_class.retry_due).to match_ids([failed, synced, retry_yesterday])
    end
  end

  describe '.never' do
    it 'returns registries that are never synced' do
      never = create(:geo_file_registry, retry_count: nil, success: false)

      expect(described_class.never).to match_ids([never])
    end
  end

  describe '.with_status' do
    it 'finds the registries with status "synced"' do
      expect(described_class).to receive(:synced)

      described_class.with_status('synced')
    end

    it 'finds the registries with status "never"' do
      expect(described_class).to receive(:never)

      described_class.with_status('never')
    end
    it 'finds the registries with status "failed"' do
      expect(described_class).to receive(:failed)

      described_class.with_status('failed')
    end
  end

  describe '#synchronization_state' do
    it 'returns :synced for a successful synced registry' do
      expect(synced.synchronization_state).to eq(:synced)
    end

    it 'returns :never for a successful registry never synced' do
      never = build(:geo_file_registry, success: false, retry_count: nil)

      expect(never.synchronization_state).to eq(:never)
    end

    it 'returns :failed for a failed registry' do
      expect(failed.synchronization_state).to eq(:failed)
    end
  end
end
