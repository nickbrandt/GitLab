# frozen_string_literal: true

module Elastic
  module Latest
    class ProjectWikiClassProxy < ApplicationClassProxy
      include GitClassProxy

      def es_type
        'wiki_blob'
      end
    end
  end
end
