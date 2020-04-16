# frozen_string_literal: true

module StatusPage
  class PostProcessPipeline < ::Banzai::Pipeline::PostProcessPipeline
    def self.filters
      super + [ImageFilter]
    end
  end
end
