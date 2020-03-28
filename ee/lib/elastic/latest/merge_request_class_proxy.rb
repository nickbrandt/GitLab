# frozen_string_literal: true

module Elastic
  module Latest
    class MergeRequestClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        query_hash =
          if query =~ /\!(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            basic_query_hash(%w(title^2 description), query)
          end

        options[:features] = 'merge_requests'
        query_hash = project_ids_filter(query_hash, options)

        search(query_hash, options)
      end
    end
  end
end
