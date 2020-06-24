# frozen_string_literal: true

module Analytics
  module Reports
    class PagesController < ::ApplicationController
      layout 'report_pages'

      before_action do
        render_404 unless feature_enabled? && feature_available?
      end

      def feature_enabled?
        Feature.enabled?(Gitlab::Analytics::REPORT_PAGES_FEATURE_FLAG)
      end

      def feature_available?
        ::License.feature_available?(:group_activity_analytics)
      end
    end
  end
end
