# frozen_string_literal: true

module StatusPage
  # HTML filter that converts lazy loaded img nodes to standard HTML spec img nodes
  # We do not need to lazy load images on the Status Page
  class ImageFilter < HTML::Pipeline::Filter
    LAZY_IMAGE_SRC_REGEX = %r{/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*)}.freeze

    def call
      return doc unless context[:issue_iid]

      doc.css('img').each do |image_node|
        image_node['class'] = 'gl-image'
        original_src = image_node.delete('data-src').value
        matches = LAZY_IMAGE_SRC_REGEX.match(original_src)
        next unless matches && matches[:secret] && matches[:file]

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
