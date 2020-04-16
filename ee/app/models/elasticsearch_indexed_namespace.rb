# frozen_string_literal: true

class ElasticsearchIndexedNamespace < ApplicationRecord
  include ElasticsearchIndexedContainer
  include EachBatch

  self.primary_key = :namespace_id

  belongs_to :namespace

  validates :namespace_id, presence: true, uniqueness: true

  scope :namespace_in, -> (namespaces) { where(namespace_id: namespaces) }

  BATCH_OPERATION_SIZE = 1000

  def self.target_attr_name
    :namespace_id
  end

  def self.limited(ignore_descendants: false)
    namespaces = Namespace.with_route.where(id: target_ids)

    return namespaces if ignore_descendants

    Gitlab::ObjectHierarchy.new(namespaces).base_and_descendants
  end

  def self.drop_limited_ids_cache!
    # To prevent stale cache we also drop ElasticsearchIndexedProject cache since it uses ElasticsearchIndexedNamespace
    ElasticsearchIndexedProject.drop_limited_ids_cache!
    super
  end

  def self.index_first_n_namespaces_of_plan(plan, number_of_namespaces)
    indexed_namespaces = self.select(:namespace_id)
    now = Time.now

    ids = GitlabSubscription
      .with_hosted_plan(plan)
      .where.not(namespace_id: indexed_namespaces)
      .order(namespace_id: :asc)
      .limit(number_of_namespaces)
      .pluck(:namespace_id)

    ids.in_groups_of(BATCH_OPERATION_SIZE, false) do |batch_ids|
      insert_rows = batch_ids.map do |id|
        # Ensure ordering with incremental created_at,
        # so rollback can start from the bigger namespace_id
        now += 1.0e-05.seconds
        { created_at: now, updated_at: now, namespace_id: id }
      end

      Gitlab::Database.bulk_insert(table_name, insert_rows)

      jobs = batch_ids.map { |id| [id, :index] }

      ElasticNamespaceIndexerWorker.bulk_perform_async(jobs) # rubocop:disable Scalability/BulkPerformWithContext, CodeReuse/Worker
    end

    drop_limited_ids_cache!
  end

  def self.unindex_last_n_namespaces_of_plan(plan, number_of_namespaces)
    namespaces_under_plan = GitlabSubscription.with_hosted_plan(plan).select(:namespace_id)

    ids = where(namespace: namespaces_under_plan)
      .order(created_at: :desc)
      .limit(number_of_namespaces)
      .pluck(:namespace_id)

    ids.in_groups_of(BATCH_OPERATION_SIZE, false) do |batch_ids|
      where(namespace_id: batch_ids).delete_all

      jobs = batch_ids.map { |id| [id, :delete] }

      ElasticNamespaceIndexerWorker.bulk_perform_async(jobs) # rubocop:disable Scalability/BulkPerformWithContext, CodeReuse/Worker
    end

    drop_limited_ids_cache!
  end

  private

  def index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :index)
  end

  def delete_from_index
    ElasticNamespaceIndexerWorker.perform_async(namespace_id, :delete)
  end
end
