# frozen_string_literal: true

module EE
  module UpdateDeploymentService
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      super.tap do |deployment|
        deployment.project.repository.log_geo_updated_event
      end
    end
  end
end
