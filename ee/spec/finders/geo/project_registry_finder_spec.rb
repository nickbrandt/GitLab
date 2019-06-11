require 'spec_helper'

describe Geo::ProjectRegistryFinder, :geo, :geo_fdw do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly when
  # using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction
  # of a different connection.
  let(:secondary) { create(:geo_node) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_repositories' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistrySyncedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_synced_repositories
    end

    it 'returns an integer' do
      expect(subject.count_synced_repositories).to be_a(Integer)
    end
  end

  describe '#count_synced_wikis' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistrySyncedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_synced_wikis
    end

    it 'returns an integer' do
      expect(subject.count_synced_wikis).to be_a(Integer)
    end
  end

  describe '#count_failed_repositories' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistrySyncFailedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_failed_repositories
    end

    it 'returns an integer' do
      expect(subject.count_failed_repositories).to be_a(Integer)
    end
  end

  describe '#count_failed_wikis' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistrySyncFailedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_failed_wikis
    end

    it 'returns an integer' do
      expect(subject.count_failed_wikis).to be_a(Integer)
    end
  end

  describe '#count_verified_repositories' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryVerifiedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_verified_repositories
    end

    it 'returns an integer' do
      expect(subject.count_verified_repositories).to be_a(Integer)
    end
  end

  describe '#count_verified_wikis' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryVerifiedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_verified_wikis
    end

    it 'returns an integer' do
      expect(subject.count_verified_wikis).to be_a(Integer)
    end
  end

  describe '#count_verification_failed_repositories' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryVerificationFailedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_verification_failed_repositories
    end

    it 'returns an integer' do
      expect(subject.count_verification_failed_repositories).to be_a(Integer)
    end
  end

  describe '#count_verification_failed_wikis' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryVerificationFailedFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_verification_failed_wikis
    end

    it 'returns an integer' do
      expect(subject.count_verification_failed_wikis).to be_a(Integer)
    end
  end

  describe '#count_repositories_retrying_verification' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryRetryingVerificationFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_repositories_retrying_verification
    end

    it 'returns an integer' do
      expect(subject.count_repositories_retrying_verification).to be_a(Integer)
    end
  end

  describe '#count_wikis_retrying_verification' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryRetryingVerificationFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_wikis_retrying_verification
    end

    it 'returns an integer' do
      expect(subject.count_wikis_retrying_verification).to be_a(Integer)
    end
  end

  describe '#count_repositories_checksum_mismatch' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryMismatchFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_repositories_checksum_mismatch
    end

    it 'returns an integer' do
      expect(subject.count_repositories_checksum_mismatch).to be_a(Integer)
    end
  end

  describe '#count_wikis_checksum_mismatch' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryMismatchFinder) do |finder|
        expect(finder).to receive(:execute).once.and_call_original
      end

      subject.count_wikis_checksum_mismatch
    end

    it 'returns an integer' do
      expect(subject.count_wikis_checksum_mismatch).to be_a(Integer)
    end
  end

  describe '#find_unsynced_projects' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectUnsyncedFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_unsynced_projects(shard_name: 'default', batch_size: 100)
    end
  end

  describe '#find_projects_updated_recently' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectUpdatedRecentlyFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_projects_updated_recently(shard_name: 'default', batch_size: 100)
    end
  end

  describe '#find_failed_project_registries' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistrySyncFailedFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_failed_project_registries('repository')
    end
  end

  describe '#find_registries_to_verify' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryPendingVerificationFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)
    end
  end

  describe '#find_verification_failed_project_registries' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryVerificationFailedFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_verification_failed_project_registries('repository')
    end
  end

  describe '#find_checksum_mismatch_project_registries' do
    it 'delegates to the proper finder' do
      expect_next_instance_of(Geo::ProjectRegistryMismatchFinder) do |finder|
        expect(finder).to receive(:execute).once
      end

      subject.find_checksum_mismatch_project_registries('repository')
    end
  end
end
