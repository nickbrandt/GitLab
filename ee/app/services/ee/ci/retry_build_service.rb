# frozen_string_literal: true

module EE
  module Ci
    module RetryBuildService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :clone_accessors
        def clone_accessors
          (super + extra_accessors).freeze
        end

        override :extra_accessors
        def extra_accessors
          %i[dast_site_profile dast_scanner_profile secrets].freeze
        end
      end

      private

      override :check_access!
      def check_access!(build)
        super

        if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
          ::Gitlab::AppLogger.info(
            message: 'Credit card required to be on file in order to retry build',
            project_path: project.full_path,
            user_id: current_user.id,
            plan: project.root_namespace.actual_plan_name
          )

          raise ::Gitlab::Access::AccessDeniedError, 'Credit card required to be on file in order to retry a build'
        end
      end

      override :check_assignable_runners!
      def check_assignable_runners!(build)
        runner_minutes = ::Gitlab::Ci::Minutes::RunnersAvailability.new(project)
        return if runner_minutes.available?(build.build_matcher)

        build.drop!(:ci_quota_exceeded)
      end
    end
  end
end
