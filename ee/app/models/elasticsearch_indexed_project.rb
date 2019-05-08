# frozen_string_literal: true

class ElasticsearchIndexedProject < ApplicationRecord
  include ElasticsearchIndexedContainer
  include EachBatch

  self.primary_key = :project_id

  belongs_to :project

  validates :project_id, presence: true, uniqueness: true

  def self.target_attr_name
    :project_id
  end

  private

  def index
    if Gitlab::CurrentSettings.elasticsearch_indexing? && project.searchable?
      ElasticIndexerWorker.perform_async(:index, project.class.to_s, project.id, project.es_id)
    end
  end

  def delete_from_index
    if Gitlab::CurrentSettings.elasticsearch_indexing? && project.searchable?
      ElasticIndexerWorker.perform_async(
        :delete,
        project.class.to_s,
        project.id,
        project.es_id,
        es_parent: project.es_parent
      )
    end
  end
end
