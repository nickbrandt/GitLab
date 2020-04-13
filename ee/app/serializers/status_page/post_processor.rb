# frozen_string_literal: true

module StatusPage
  module PostProcessor
    PROCESSOR_PIPELINE = [
      ::StatusPage::Processors::Redactor,
      ::StatusPage::Processors::ImageTransformer
    ].freeze

    def self.process(html, issue_iid:)
      PROCESSOR_PIPELINE.each do |processor|
        html = processor.process(html, issue_iid: issue_iid)
      end

      html.html_safe
    end
  end
end
