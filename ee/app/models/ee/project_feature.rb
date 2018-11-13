# frozen_string_literal: true

module EE
  module ProjectFeature
    extend ActiveSupport::Concern

    prepended do
      after_commit on: :update do
        if ::Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing?
          ElasticIndexerWorker.perform_async(:update, 'Project', project_id, project.es_id)
        end
      end
    end
  end
end
