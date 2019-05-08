# frozen_string_literal: true

module Elastic
  class IndexProjectsService
    def execute
      if Gitlab::CurrentSettings.elasticsearch_limit_indexing?
        IndexProjectsByIdService.new.execute(
          project_ids: ElasticsearchIndexedProject.target_ids,
          namespace_ids: ElasticsearchIndexedNamespace.target_ids
        )
      else
        IndexProjectsByRangeService.new.execute
      end
    end
  end
end
