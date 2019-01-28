# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern

      prepended do
        # rubocop:disable Cop/ActiveRecordSerialize
        serialize :options
        serialize :yaml_variables, ::Gitlab::Serializer::Ci::Variables
        # rubocop:enable Cop/ActiveRecordSerialize

        has_many :sourced_pipelines, class_name: ::Ci::Sources::Pipeline,
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
        yaml_variables.to_a.map { |hash| hash.except(:public) }
      end
    end
  end
end
