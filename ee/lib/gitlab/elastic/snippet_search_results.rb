# frozen_string_literal: true

module Gitlab
  module Elastic
    class SnippetSearchResults < Gitlab::Elastic::SearchResults
      def objects(scope, page = 1)
        page = (page || 1).to_i

        case scope
        when 'snippet_titles'
          eager_load(snippet_titles, page, eager: { project: [:route, :namespace] })
        when 'snippet_blobs'
          eager_load(snippet_blobs, page, eager: { project: [:route, :namespace] })
        end
      end

      def formatted_count(scope)
        case scope
        when 'snippet_titles'
          snippet_titles_count.to_s
        when 'snippet_blobs'
          snippet_blobs_count.to_s
        else
          super
        end
      end

      def snippet_titles_count
        limited_snippet_titles_count
      end

      def snippet_blobs_count
        limited_snippet_blobs_count
      end

      private

      def snippet_titles
        Snippet.elastic_search(query, options: base_options)
      end

      def snippet_blobs
        Snippet.elastic_search_code(query, options: base_options)
      end

      def limited_snippet_titles_count
        @limited_snippet_titles_count ||= snippet_titles.total_count
      end

      def limited_snippet_blobs_count
        @limited_snippet_blobs_count ||= snippet_blobs.total_count
      end

      def paginated_objects(relation, page)
        super.records
      end
    end
  end
end
