# frozen_string_literal: true

module EE
  module Projects
    module ForksController
      extend ::Gitlab::Utils::Override

      private

      override :load_forks
      def load_forks
        super.with_compliance_framework_settings
      end
    end
  end
end
