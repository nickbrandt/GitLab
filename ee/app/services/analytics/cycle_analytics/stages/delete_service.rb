# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stages
      class DeleteService < BaseService
        def initialize(parent:, current_user:, params:)
          super

          @stage = Analytics::CycleAnalytics::StageFinder.new(parent: parent, stage_id: params[:id]).execute
        end

        def execute
          return forbidden if !can?(current_user, :delete_group_stage, parent) || @stage.default_stage?

          @stage.destroy!

          success(@stage, :ok)
        end
      end
    end
  end
end
