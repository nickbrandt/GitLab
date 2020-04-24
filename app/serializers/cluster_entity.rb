# frozen_string_literal: true

class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :environment_scope
  expose :name
  expose :status_name, as: :status
  expose :status_reason
  expose :applications, using: ClusterApplicationEntity
end
