# frozen_string_literal: true

module EE
  module Projects
    module CleanupService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        project.repository.log_geo_updated_event
      end
    end
  end
end
