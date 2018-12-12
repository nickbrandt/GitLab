# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern

      prepended do
        has_many :sourced_pipelines, class_name: ::Ci::Sources::Pipeline,
                                     foreign_key: :source_job_id

        state_machine :status do
          after_transition any => [:pending] do |bridge|
            bridge.run_after_commit do
              bridge.schedule_downstream_pipeline!

              # 1. schedule pipeline creation async
              # 2. scheduled pipeline calls-back to change state to running
              #    when it gets created successfully
              # 3. if no downstream pipeline can not be created because of
              #    various reasons like lack of access then we change state to
              #    failed with a reason
            end
          end

          after_transition pending: :running do |bridge|
            bridge.run_after_commit do
            end
          end
        end
      end

      def schedule_downstream_pipeline!
        raise NotImplementedError
      end
    end
  end
end
