# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class BaseService
      include Gitlab::Allowable

      def initialize(parent:, current_user:, params: {})
        @parent = parent
        @current_user = current_user
      end

      def execute
        raise NotImplementedError
      end

      private

      attr_reader :parent, :current_user, :params

      def success(stage, http_status = :created)
        ServiceResponse.success(payload: { stage: stage }, http_status: http_status)
      end

      def error(stage)
        ServiceResponse.error(message: 'Invalid parameters', payload: { errors: stage.errors }, http_status: :unprocessable_entity)
      end

      def not_found
        ServiceResponse.error(message: 'Stage not found', payload: {}, http_status: :not_found)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', payload: {}, http_status: :forbidden)
      end

      def persist_default_stages!
        persisted_default_stages = parent.cycle_analytics_stages.default_stages

        # make sure that we persist default stages only once
        stages_to_persist = build_default_stages.select do |new_default_stage|
          !persisted_default_stages.find { |s| s.name.eql?(new_default_stage.name) }
        end

        stages_to_persist.each(&:save!)
      end

      def build_default_stages
        Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
          parent.cycle_analytics_stages.build(params)
        end
      end
    end
  end
end
