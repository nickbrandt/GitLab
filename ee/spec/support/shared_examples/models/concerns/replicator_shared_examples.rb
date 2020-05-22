# frozen_string_literal: true

# Include these shared examples in BlobReplicatorStrategy,
# RepositoryReplicatorStrategy, etc.
#
# Required let variables:
#
#   - `replicator` should be an instance of the Replicator class being tested, e.g. PackageFileReplicator
#   - `model_record` should be a valid instance of the model class. It may be unpersisted.
#   - `primary` should be the primary GeoNode
#   - `secondary` should be a secondary GeoNode
#
RSpec.shared_examples 'a replicator' do
  include EE::GeoHelpers

  describe '#parent_project_id' do
    it 'is implemented if needed' do
      expect { replicator.parent_project_id }.not_to raise_error
    end
  end
end
