# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern
      include ::Gitlab::Utils::StrongMemoize

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

            bridge.run_after_commit do
              bridge.subscribe_to_upstream!
            end
          end

          event :manual do
            transition all => :manual
          end

          event :scheduled do
            transition all => :scheduled
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

      def inherit_status_from_upstream!
        return false unless upstream_pipeline
        return false if self.status == upstream_pipeline.status

        case upstream_pipeline.status
        when 'running'
          self.run!
        when 'success'
          self.success!
        when 'failed'
          self.drop!
        when 'canceled'
          self.cancel!
        when 'skipped'
          self.skip!
        when 'manual'
          self.manual!
        when 'scheduled'
          self.scheduled!
        else
          false
        end
      end

      def inherit_status_from_downstream!(pipeline)
        case pipeline.status
        when 'success'
          self.success!
        when 'failed', 'canceled', 'skipped'
          self.drop!
        else
          false
        end
      end

      def target_user
        self.user
      end

      def target_project_path
        downstream_project || upstream_project
      end

      def downstream_project
        strong_memoize(:downstream_project) do
          options&.dig(:trigger, :project)
        end
      end

      def upstream_project
        strong_memoize(:upstream_project) do
          options&.dig(:bridge_needs, :pipeline)
        end
      end

      def target_ref
        branch = options&.dig(:trigger, :branch)
        return unless branch

        scoped_variables.to_runner_variables.yield_self do |all_variables|
          ::ExpandVariables.expand(branch, all_variables)
        end
      end

      def dependent?
        strong_memoize(:dependent) do
          options&.dig(:trigger, :strategy) == 'depend'
        end
      end

      def downstream_variables
        variables = scoped_variables.concat(pipeline.persisted_variables)

        variables.to_runner_variables.yield_self do |all_variables|
          yaml_variables.to_a.map do |hash|
            { key: hash[:key], value: ::ExpandVariables.expand(hash[:value], all_variables) }
          end
        end
      end
    end
  end
end
