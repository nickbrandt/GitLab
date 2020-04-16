# frozen_string_literal: true

module StatusPage
  class PublishBaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(project:)
      @project = project
    end

    def execute(*args)
      return error_feature_not_available unless feature_available?
      return error_no_storage_client unless storage_client

      process(*args)
    end

    private

    attr_reader :project

    def process(*args)
      raise NotImplementedError
    end

    def storage_client
      strong_memoize(:strong_memoize) do
        project.status_page_setting&.storage_client
      end
    end

    def serializer
      strong_memoize(:serializer) do
        # According to development/reusing_abstractions.html#abstractions
        # serializers can only be used from controllers.
        # For the Status Page however, we generate JSON in background jobs.
        # rubocop: disable CodeReuse/Serializer
        StatusPage::IncidentSerializer.new
        # rubocop: enable CodeReuse/Serializer
      end
    end

    def feature_available?
      project.status_page_setting&.enabled?
    end

    def upload_json(key, json)
      return error_limit_exceeded(key) if limit_exceeded?(json)

      content = json.to_json
      storage_client.upload_object(key, content)

      success(json_object_key: key)
    end

    def delete_object(key)
      storage_client.delete_object(key)

      success(json_object_key: key)
    end

    def delete_objects_recursive(key_prefix:)
      storage_client.recursive_delete(key_prefix)

      success
    end

    def limit_exceeded?(json)
      !Gitlab::Utils::DeepSize
        .new(json, max_size: Storage::JSON_MAX_SIZE)
        .valid?
    end

    def error(message, payload = {})
      ServiceResponse.error(message: message, payload: payload)
    end

    def error_limit_exceeded(key)
      error("Failed to upload #{key}: Limit exceeded")
    end

    def error_feature_not_available
      error('Feature not available')
    end

    def error_no_storage_client
      error('No storage client available. Is the status page setting activated?')
    end

    def success(payload = {})
      ServiceResponse.success(payload: payload)
    end
  end
end
