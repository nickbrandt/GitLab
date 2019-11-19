# frozen_string_literal: true

module Elastic
  module Latest
    class SnippetInstanceProxy < ApplicationInstanceProxy
      MAX_INDEX_SIZE = 1.megabyte

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [
          :id,
          :title,
          :file_name,
          :content,
          :created_at,
          :updated_at,
          :project_id,
          :author_id,
          :visibility_level
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        if data['content'].bytesize > MAX_INDEX_SIZE
          data['content'] = data['content'].mb_chars.limit(MAX_INDEX_SIZE).to_s # rubocop: disable CodeReuse/ActiveRecord
        end

        data.merge(generic_attributes)
      end

      # TODO: Reenable support for public/internal project snippets
      # https://gitlab.com/gitlab-org/gitlab/issues/2358
      def es_parent
        nil
      end
    end
  end
end
