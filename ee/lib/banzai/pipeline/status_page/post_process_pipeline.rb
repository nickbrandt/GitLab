# frozen_string_literal: true

module Banzai
  module Pipeline
    module StatusPage
      class PostProcessPipeline < ::Banzai::Pipeline::PostProcessPipeline
        def self.filters
          super + [Filter::StatusPage::ImageFilter]
        end
      end
    end
  end
end
