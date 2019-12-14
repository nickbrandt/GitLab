# frozen_string_literal: true

module Elastic
  module Latest
    class ProjectWikiInstanceProxy < ApplicationInstanceProxy
      include GitInstanceProxy

      delegate :project, to: :target
      delegate :id, to: :project, prefix: true

      private

      def repository_id
        "wiki_#{project.id}"
      end
    end
  end
end
