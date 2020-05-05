# frozen_string_literal: true

module StatusPage
  module Pipeline
    class PostProcessPipeline < ::Banzai::Pipeline::PostProcessPipeline
      def self.filters
        super + [StatusPage::Filter::ImageFilter]
      end
    end
  end
end
