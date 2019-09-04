# frozen_string_literal: true

module EE
  module MergeRequestMetricsService
    extend ::Gitlab::Utils::Override

    delegate :merge_request, to: :@merge_request_metrics

    override :merge
    def merge(event)
      data = {
        merged_by_id: event.author_id,
        merged_at: event.created_at
      }.merge(productivity_calculator.productivity_data)

      update!(data)
    end

    private

    def productivity_calculator
      @productivity_calculator ||= Analytics::ProductivityCalculator.new(merge_request)
    end
  end
end
