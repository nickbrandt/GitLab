# frozen_string_literal: true

module Projects
  module Analytics
    class CodeReviewsController < Projects::ApplicationController
      before_action :check_code_review_analytics_available!

      def index
      end
    end
  end
end
