# frozen_string_literal: true

class ElasticBatchProjectIndexerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :search

  # Batch indexing is a generally a onetime option, so give finer control over
  # queuing and concurrency

  # This worker is long-running, but idempotent, so retry many times if
  # necessary
  sidekiq_options retry: 10

  def perform(start, finish)
    projects = build_relation(start, finish)

    projects.find_each { |project| run_indexer(project) }
  end

  private

  def run_indexer(project)
    return unless project.use_elasticsearch?

    # Ensure we remove the hold on the project, no matter what, so ElasticCommitIndexerWorker can do its thing
    # We do this before the indexer starts to avoid the possibility of pushes coming in during this time not
    # being indexed.
    Gitlab::Redis::SharedState.with { |redis| redis.srem(:elastic_projects_indexing, project.id) }

    logger.info "Indexing #{project.full_name} (ID=#{project.id})..."

    Gitlab::Elastic::Indexer.new(project).run

    logger.info "Indexing #{project.full_name} (ID=#{project.id}) is done!"
  rescue => err
    logger.warn("#{err.message} indexing #{project.full_name} (ID=#{project.id}), trace - #{err.backtrace}")
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def build_relation(start, finish)
    relation = Project.includes(:index_status)

    table = Project.arel_table
    relation = relation.where(table[:id].gteq(start)) if start
    relation = relation.where(table[:id].lteq(finish)) if finish

    relation
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
