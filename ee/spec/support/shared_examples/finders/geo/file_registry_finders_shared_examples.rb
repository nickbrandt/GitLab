# frozen_string_literal: true

RSpec.shared_examples 'a file registry finder' do
  it 'responds to file registry finder methods' do
    file_registry_finder_methods = %i{
      syncable
      count_syncable
      count_synced
      count_failed
      count_synced_missing_on_primary
      count_registry
      find_unsynced
      find_migrated_local
      find_retryable_failed_registries
      find_retryable_synced_missing_on_primary_registries
    }

    file_registry_finder_methods.each do |method|
      expect(subject).to respond_to(method)
    end
  end
end
