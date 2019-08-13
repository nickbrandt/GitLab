# frozen_string_literal: true

class DependencyEntity < Grape::Entity
  include RequestAwareEntity

  class LocationEntity < Grape::Entity
    expose :blob_path, :path
  end

  class VulnerabilityEntity < Grape::Entity
    expose :name, :severity
  end

  expose :name, :packager, :version
  expose :location, using: LocationEntity
  expose :vulnerabilities, using: VulnerabilityEntity, if: ->(_) { can_read_vulnerabilities? }

  private

  def can_read_vulnerabilities?
    can?(request.user, :read_project_security_dashboard, request.project)
  end
end
