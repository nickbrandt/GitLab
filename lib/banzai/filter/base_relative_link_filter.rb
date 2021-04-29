# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    class BaseRelativeLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      protected

      def linkable_attributes
        if Feature.enabled?(:optimize_linkable_attributes, project, default_enabled: :yaml)
          # Nokorigi Nodeset#search performs badly for documents with many nodes
          #
          # Here we store fetched attributes in the shared variable "result"
          # This variable is passed through the chain of filters and can be
          # accessed by them
          result[:linkable_attributes] ||= fetch_linkable_attributes
        else
          strong_memoize(:linkable_attributes) do
            fetch_linkable_attributes
          end
        end
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def project
        context[:project]
      end

      private

      def unescape_and_scrub_uri(uri)
        Addressable::URI.unescape(uri).scrub.delete("\0")
      end

      def fetch_linkable_attributes
        attrs = []
        attrs += doc.search(xpath_query).flat_map do |el|
          [el.attribute('href'), el.attribute('src'), el.attribute('data-src')]
        end

        attrs.reject { |attr| attr.blank? || attr.value.start_with?('//') }
      end

      def xpath_query
        strong_memoize(:xpath_query) do
          tag_names = %w[a img video audio]
          not_gfm = "[not(contains(concat(' ', @class, ' '), ' gfm '))]"

          # We need to use both `.//<tag>` and `<tag>` for xpath search
          # because of https://github.com/sparklemotion/nokogiri/issues/572
          tag_names.map {|t| ".//#{t}#{not_gfm}|#{t}#{not_gfm}"}.join('|')
        end
      end
    end
  end
end
