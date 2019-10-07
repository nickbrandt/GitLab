# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageFinder
      NUMBERS_ONLY = /\A\d+\z/.freeze

      def initialize(parent:, stage_id:)
        @parent = parent
        @stage_id = stage_id
      end

      def execute
        if in_memory_default_stage?
          build_in_memory_stage_by_name
        else
          parent.cycle_analytics_stages.find(stage_id)
        end
      end

      private

      attr_reader :parent, :stage_id

      def in_memory_default_stage?
        !NUMBERS_ONLY.match?(stage_id.to_s)
      end

      def build_in_memory_stage_by_name
        parent.cycle_analytics_stages.build(find_in_memory_stage)
      end

      def find_in_memory_stage
        # raise ActiveRecord::RecordNotFound, so it will behave similarly to AR models and produce 404 response in the controller
        raw_stage = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.find do |hash|
          hash[:name].eql?(stage_id)
        end

        raise(ActiveRecord::RecordNotFound, "Stage with id '#{stage_id}' could not be found") unless raw_stage

        raw_stage
      end
    end
  end
end
