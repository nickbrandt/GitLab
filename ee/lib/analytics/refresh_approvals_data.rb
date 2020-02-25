# frozen_string_literal: true

module Analytics
  class RefreshApprovalsData
    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute(force: false)
      metrics = merge_request.ensure_metrics

      return if !force && metrics.first_approved_at

      metrics.update!(first_approved_at: ProductivityCalculator.new(merge_request).first_approved_at)
    end

    private

    attr_reader :merge_request
  end
end
