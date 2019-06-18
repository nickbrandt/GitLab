# frozen_string_literal: true

class DependencyEntity < Grape::Entity
  class LocationEntity < Grape::Entity
    expose :blob_path, :path
  end

  expose :name, :packager, :version
  expose :location, using: LocationEntity
end
