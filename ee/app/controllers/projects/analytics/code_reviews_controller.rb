# frozen_string_literal: true

module Projects
  module Analytics
    class CodeReviewsController < Projects::ApplicationController
      before_action :authorize_read_code_review_analytics!

      def index
      end
    end
  end
end
