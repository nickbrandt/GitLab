# frozen_string_literal: true

module Elastic
  module SnippetsSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
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

        # ES6 is now single-type per index, so we implement our own typing
        data['type'] = es_type

        data
      end

      def self.elastic_search(query, options: {})
        query_hash = basic_query_hash(%w(title file_name), query)

        query_hash = filter(query_hash, options[:user])

        self.__elasticsearch__.search(query_hash)
      end

      def self.elastic_search_code(query, options: {})
        query_hash = basic_query_hash(%w(content), query)
        query_hash = filter(query_hash, options[:user])

        self.__elasticsearch__.search(query_hash)
      end

      def self.filter(query_hash, user)
        return query_hash if user && user.full_private_access?

        filter = if user
                   {
                     bool: {
                       should: [
                         { term: { author_id: user.id } },
                         { terms: { project_id: authorized_project_ids_for_user(user) } },
                         {
                           bool: {
                             filter: { terms: { visibility_level: [Snippet::PUBLIC, Snippet::INTERNAL] } },
                             must_not: { exists: { field: 'project_id' } }
                           }
                         }
                       ]
                     }
                   }
                 else
                   {
                     bool: {
                       filter: { term: { visibility_level: Snippet::PUBLIC } },
                       must_not: { exists: { field: 'project_id' } }
                     }
                   }
                 end

        query_hash[:query][:bool][:filter] = filter
        query_hash
      end

      def self.authorized_project_ids_for_user(user)
        if Ability.allowed?(user, :read_cross_project)
          user.authorized_projects.pluck(:id)
        else
          []
        end
      end
    end
  end
end
