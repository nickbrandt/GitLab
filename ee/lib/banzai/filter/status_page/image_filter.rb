# frozen_string_literal: true

module Banzai
  module Filter
    module StatusPage
      # HTML filter that converts lazy loaded img nodes to standard HTML spec img nodes
      # We do not need to lazy load images on the Status Page
      class ImageFilter < HTML::Pipeline::Filter
        LAZY_IMAGE_SRC_REGEX = %r{/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*)}.freeze

        def call
          doc.css('img').each do |image_node|
            image_node['class'] = 'gl-image'
            original_src = image_node.delete('data-src')
            matches = original_src.match(LAZY_IMAGE_SRC_REGEX)
            image_node['src'] = ::StatusPage::Storage.upload_path(
              context[:issue_iid],
              matches[:secret],
              matches[:file]
            )
          end

          doc.to_html
        end
      end
    end
  end
end
