# frozen_string_literal: true

class ElasticsearchIndexedNamespace < ApplicationRecord
  include ElasticsearchIndexedContainer
  include EachBatch

  self.primary_key = :namespace_id

  belongs_to :namespace

  validates :namespace_id, presence: true, uniqueness: true

  def self.target_attr_name
    :namespace_id
  end

  private

  def index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :index)
  end

  def delete_from_index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :delete)
  end
end
