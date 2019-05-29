# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern

      prepended do
        include ::Ci::Metadatable

        # rubocop:disable Cop/ActiveRecordSerialize
        serialize :options
        serialize :yaml_variables, ::Gitlab::Serializer::Ci::Variables
        # rubocop:enable Cop/ActiveRecordSerialize

        belongs_to :upstream_pipeline, class_name: "::Ci::Pipeline",
                                       foreign_key: :upstream_pipeline_id
        has_many :sourced_pipelines, class_name: "::Ci::Sources::Pipeline",
                                     foreign_key: :source_job_id

        state_machine :status do
          after_transition created: :pending do |bridge|
            bridge.run_after_commit do
              bridge.schedule_downstream_pipeline!
            end
          end
        end
      end

      def schedule_downstream_pipeline!
        ::Ci::CreateCrossProjectPipelineWorker.perform_async(self.id)
      end

      def target_user
        self.user
      end

      def target_project_path
        options&.dig(:trigger, :project)
      end

      def target_ref
        options&.dig(:trigger, :branch)
      end

      def downstream_variables
        scoped_variables.to_runner_variables.yield_self do |all_variables|
          yaml_variables.to_a.map do |hash|
            { key: hash[:key], value: ::ExpandVariables.expand(hash[:value], all_variables) }
          end
        end
      end
    end
  end
end
