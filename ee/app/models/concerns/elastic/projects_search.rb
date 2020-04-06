# frozen_string_literal: true

module Elastic
  module ProjectsSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    INDEXED_ASSOCIATIONS = [
      :issues,
      :merge_requests,
      :snippets,
      :notes,
      :milestones
    ].freeze

    included do
      def use_elasticsearch?
        ::Gitlab::CurrentSettings.elasticsearch_indexes_project?(self)
      end

      # TODO: ElasticIndexerWorker does extra work for project hooks, so we
      # can't use the incremental-bulk indexer for projects yet.
      #
      # https://gitlab.com/gitlab-org/gitlab/issues/207494
      def maintain_elasticsearch_create
        ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id, self.es_id)
      end

      def maintain_elasticsearch_update
        ElasticIndexerWorker.perform_async(:update, self.class.to_s, self.id, self.es_id)
      end

      def maintain_elasticsearch_destroy
        ElasticIndexerWorker.perform_async(:delete, self.class.to_s, self.id, self.es_id, es_parent: self.es_parent)
      end

      def each_indexed_association
        INDEXED_ASSOCIATIONS.each do |association_name|
          association = self.association(association_name)
          scope = association.scope
          klass = association.klass

          if klass == Note
            scope = scope.searchable
          end

          yield klass, scope
        end
      end
    end
  end
end
