# frozen_string_literal: true

class ElasticsearchIndexedNamespace < ApplicationRecord
  include ElasticsearchIndexedContainer
  include EachBatch

  self.primary_key = :namespace_id

  belongs_to :namespace

  validates :namespace_id, presence: true, uniqueness: true

  scope :namespace_in, -> (namespaces) { where(namespace_id: namespaces) }

  def self.target_attr_name
    :namespace_id
  end

  # rubocop: disable Naming/UncommunicativeMethodParamName
  def self.index_first_n_namespaces_of_plan(plan, n)
    indexed_namespaces = self.select(:namespace_id)

    GitlabSubscription
      .with_hosted_plan(plan)
      .where.not(namespace_id: indexed_namespaces)
      .order(namespace_id: :asc)
      .limit(n)
      .pluck(:namespace_id)
      .each { |id| create!(namespace_id: id) }
  end

  def self.unindex_last_n_namespaces_of_plan(plan, n)
    namespaces_under_plan = GitlabSubscription.with_hosted_plan(plan).select(:namespace_id)

    # rubocop: disable Cop/DestroyAll
    # destroy_all is used in order to trigger `delete_from_index` callback
    where(namespace: namespaces_under_plan)
      .order(created_at: :desc)
      .limit(n)
      .destroy_all
    # rubocop: enable Cop/DestroyAll
  end
  # rubocop: enable Naming/UncommunicativeMethodParamName

  private

  def index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :index)
  end

  def delete_from_index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :delete)
  end
end
