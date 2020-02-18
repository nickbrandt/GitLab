# frozen_string_literal: true

class GeoRepositoryDestroyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include GeoQueue

  def perform(id, name, disk_path, storage_name)
    Geo::RepositoryDestroyService.new(id, name, disk_path, storage_name).execute
  end
end
