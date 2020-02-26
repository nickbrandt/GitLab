# frozen_string_literal: true

# For each project in range,
# indexing the repository, wiki and its nested models
# (e.g. )issues and notes etc.)
# Intended for full site indexing.
class ElasticFullIndexWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 2
  feature_category :search

  def perform(start_id, end_id)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    failed_ids = []

    Project.id_in(start_id..end_id).find_each do |project|
      Elastic::IndexRecordService.new.execute(project, true)
    rescue Elastic::IndexRecordService::ImportError
      failed_ids << project.id
    end

    if failed_ids.present?
      Elastic::IndexProjectsByIdService.new.execute(project_ids: failed_ids)
    end
  end
end
