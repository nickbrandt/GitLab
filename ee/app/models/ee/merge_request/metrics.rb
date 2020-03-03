# frozen_string_literal: true

module EE
  module MergeRequest
    module Metrics
      def review_time
        return unless review_start_at

        review_end_at - review_start_at
      end

      def review_start_at
        first_comment_at
      end

      def review_end_at
        merged_at || Time.now
      end
    end
  end
end
