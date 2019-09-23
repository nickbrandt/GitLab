# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageListService
      include Gitlab::Allowable

      def initialize(parent:, current_user:)
        @parent = parent
        @current_user = current_user
      end

      def execute
        return forbidden unless allowed?

        success(build_default_stages)
      end

      private

      attr_reader :parent, :current_user

      def build_default_stages
        Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
          parent.cycle_analytics_stages.build(params)
        end
      end

      def success(stages)
        ServiceResponse.success(payload: { stages: stages })
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end

      def allowed?
        can?(current_user, :read_group_cycle_analytics, parent)
      end
    end
  end
end
