# frozen_string_literal: true

module StatusPage
  class PublishBaseService
    JSON_MAX_SIZE = 1.megabyte

    def initialize(project:, storage_client:, serializer:)
      @project = project
      @storage_client = storage_client
      @serializer = serializer
    end

    def execute(*args)
      return error_feature_not_available unless feature_available?

      publish(*args)
    end

    private

    attr_reader :project, :storage_client, :serializer

    def publish(*args)
      raise NotImplementedError
    end

    def feature_available?
      project.feature_available?(:status_page)
    end

    def upload(key, json)
      return error_limit_exceeded(key) if limit_exceeded?(json)

      content = json.to_json
      storage_client.upload_object(key, content)

      success(object_key: key)
    rescue StatusPage::Storage::Error => e
      error(e.message, error: e)
    end

    def limit_exceeded?(json)
      !Gitlab::Utils::DeepSize.new(json, max_size: JSON_MAX_SIZE).valid?
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

    def success(payload = {})
      ServiceResponse.success(payload: payload)
    end
  end
end
