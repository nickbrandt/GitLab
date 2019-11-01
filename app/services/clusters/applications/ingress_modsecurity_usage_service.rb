# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
module Clusters
  module Applications
    ##
    # This service measures usage of the Modsecurity Web Application Firewall across the entire
    # instance's deployed environments.
    #
    # The default configuration is`AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE=DetectionOnly` so we
    # measure non-default values via definition of either ci_variables or ci_pipeline_variables.
    # Since both these values are encrypted, we must decrypt and count them in memory.
    ##
    class IngressModsecurityUsageService
      ADO_MODSEC_KEY = "AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE"

      def initialize(blocking_count: 0, disabled_count: 0)
        @blocking_count = blocking_count
        @disabled_count = disabled_count
      end

      def execute
        conditions = -> { merge(::Environment.available).where(key: ADO_MODSEC_KEY) }

        ci_pipeline_var_enabled =
          ::Ci::PipelineVariable
            .joins(pipeline: :environments)
            .merge(conditions)

        ci_var_enabled =
          ::Ci::Variable
            .joins(project: :environments)
            .merge(conditions)
            .merge(
              # Give priority to pipeline variables by excluding from dataset
              ::Ci::Variable.where.not(
                project_id: ci_pipeline_var_enabled.select('ci_pipelines.project_id')
              )
            ).select('DISTINCT environments.id, ci_variables.*')

        sum_modsec_config_counts(
          ci_pipeline_var_enabled.select('DISTINCT environments.id, ci_pipeline_variables.*')
        )
        sum_modsec_config_counts(ci_var_enabled)

        {
          ingress_modsecurity_blocking: @blocking_count,
          ingress_modsecurity_disabled: @disabled_count
        }
      end

      private

      # These are encrypted so we must decrypt and count in memory
      def sum_modsec_config_counts(dataset)
        dataset.find_each do |var|
          case var.value
          when "On" then @blocking_count += 1
          when "Off" then @disabled_count += 1
            # `else` could be default or any unsupported user input
          end
        end
      end
    end
  end
end
