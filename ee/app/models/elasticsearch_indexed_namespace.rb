# frozen_string_literal: true

class ElasticsearchIndexedNamespace < ApplicationRecord
  include EachBatch

  self.primary_key = 'namespace_id'

  after_commit :index, on: :create
  after_commit :delete_from_index, on: :destroy

  belongs_to :namespace

  validates :namespace_id, presence: true, uniqueness: true

  def self.namespace_ids
    self.pluck(:namespace_id)
  end

  private

  def index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :index)
  end

  def delete_from_index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :delete)
  end
end
