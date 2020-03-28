# frozen_string_literal: true

module EE
  module CycleAnalyticsParams
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    override :options
    def options(params)
      strong_memoize(:options) do
        super.tap do |options|
          options[:branch] = params[:branch_name]
          options[:projects] = params[:project_ids] if params[:project_ids]
          options[:group] = params[:group_id] if params[:group_id]
        end
      end
    end
  end
end
