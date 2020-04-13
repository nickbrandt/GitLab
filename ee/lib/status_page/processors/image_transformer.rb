# frozen_string_literal: true

module StatusPage
  module Processors
    module ImageTransformer
      LAZY_IMAGE_SRC_REGEX = %r{/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*?)$}.freeze

      # Convert lazy loaded img node to standard html spec img node
      # We will not lazy load images on the status page
      def self.process(html, issue_iid:)
        document = Nokogiri::HTML.parse(html)

        document.css('img').each do |image|
          image['class'] = 'gl-image'
          original_src = original_source(document)
          matches = original_src.match(LAZY_IMAGE_SRC_REGEX)
          image['src'] = StatusPage::Storage.upload_path(
            issue_iid,
            matches[:secret],
            matches[:file]
          )
          image.delete 'data-src'
        end

        document.to_html
      end

      def self.original_source(document)
        document.css('img')[0]['data-src']
      end
    end
  end
end
