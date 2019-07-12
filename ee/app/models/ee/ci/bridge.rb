# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern

      InvalidBridgeTypeError = Class.new(StandardError)

      prepended do
        include ::Ci::Metadatable

        # rubocop:disable Cop/ActiveRecordSerialize
        serialize :options
        serialize :yaml_variables, ::Gitlab::Serializer::Ci::Variables
        # rubocop:enable Cop/ActiveRecordSerialize

        belongs_to :upstream_pipeline, class_name: "::Ci::Pipeline"
        has_many :sourced_pipelines, class_name: "::Ci::Sources::Pipeline",
                                     foreign_key: :source_job_id

        state_machine :status do
          after_transition created: :pending do |bridge|
            next unless bridge.downstream_project

            bridge.run_after_commit do
              bridge.schedule_downstream_pipeline!
            end
          end

          after_transition any => :pending do |bridge|
            next unless bridge.upstream_project

            bridge.subscribe_to_upstream!
          end
        end
      end

      def schedule_downstream_pipeline!
        raise InvalidBridgeTypeError unless downstream_project

        ::Ci::CreateCrossProjectPipelineWorker.perform_async(self.id)
      end

      def subscribe_to_upstream!
        raise InvalidBridgeTypeError unless upstream_project

        ::Ci::SubscribeBridgeService.new(self.project, self.user).execute(self)
      end

      def target_user
        self.user
      end

      def target_project_path
        downstream_project || upstream_project
      end

      def downstream_project
        options&.dig(:trigger, :project)
      end

      def upstream_project
        options&.dig(:needs, :pipeline)
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
