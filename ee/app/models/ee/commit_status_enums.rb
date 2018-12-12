# frozen_string_literal: true

module EE
  module CommitStatusEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :failure_reasons
      def failure_reasons
        super.merge(protected_environment_failure: 1_000,
                    insufficient_permissions: 1_001)
      end
    end
  end
end
