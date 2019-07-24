# frozen_string_literal: true

class DependencyEntity < Grape::Entity
  class LocationEntity < Grape::Entity
    expose :blob_path, :path
  end

  class VulnerabilityEntity < Grape::Entity
    expose :name, :severity
  end

  expose :name, :packager, :version
  expose :location, using: LocationEntity
  expose :vulnerabilities, using: VulnerabilityEntity
end
