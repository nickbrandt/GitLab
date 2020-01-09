# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" links to uploads.
    #
    # Context options:
    #   :group
    #   :only_path
    #   :project
    #   :system_note
    class UploadLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      def call
        return doc if context[:system_note]

        linkable_attributes.each do |attr|
          if attr.value.start_with?('/uploads/')
            process_link_to_upload_attr(attr)
            attr.parent.add_class('gfm')
          end
        end

        doc
      end

      protected

      def linkable_attributes
        strong_memoize(:linkable_attributes) do
          attrs = []

          attrs += doc.search('a:not(.gfm)').map do |el|
            el.attribute('href')
          end

          attrs += doc.search('img:not(.gfm), video:not(.gfm), audio:not(.gfm)').flat_map do |el|
            [el.attribute('src'), el.attribute('data-src')]
          end

          attrs.reject do |attr|
            attr.blank? || attr.value.start_with?('//')
          end
        end
      end

      def process_link_to_upload_attr(html_attr)
        path_parts = [unescape_and_scrub_uri(html_attr.value)]

        if project
          path_parts.unshift(relative_url_root, project.full_path)
        elsif group
          path_parts.unshift(relative_url_root, 'groups', group.full_path, '-')
        else
          path_parts.unshift(relative_url_root)
        end

        begin
          path = Addressable::URI.escape(File.join(*path_parts))
        rescue Addressable::URI::InvalidURIError
          return
        end

        html_attr.value =
          if context[:only_path]
            path
          else
            Addressable::URI.join(Gitlab.config.gitlab.base_url, path).to_s
          end
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def group
        context[:group]
      end

      def project
        context[:project]
      end

      private

      def unescape_and_scrub_uri(uri)
        Addressable::URI.unescape(uri).scrub
      end
    end
  end
end
