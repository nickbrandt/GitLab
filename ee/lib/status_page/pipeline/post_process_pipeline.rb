# frozen_string_literal: true

module StatusPage
  module Pipeline
    class PostProcessPipeline < ::Banzai::Pipeline::PostProcessPipeline
      def self.filters
        @filters ||= super
          .dup
          .insert_before(::Banzai::Filter::ReferenceRedactorFilter,
                         StatusPage::Filter::MentionAnonymizationFilter)
          .concat(::Banzai::FilterArray[StatusPage::Filter::ImageFilter])
          .freeze
      end
    end
  end
end
