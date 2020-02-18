# frozen_string_literal: true

class ElasticCommitIndexerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :search
  sidekiq_options retry: 2

  def perform(project_id, oldrev = nil, newrev = nil, wiki = false)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    project = Project.find(project_id)

    return true unless project.use_elasticsearch?

    Gitlab::Elastic::Indexer.new(project, wiki: wiki).run(newrev)
  end
end
