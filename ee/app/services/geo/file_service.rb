# frozen_string_literal: true

module Geo
  class FileService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    attr_reader :object_type, :object_db_id

    DEFAULT_KLASS_NAME = 'File'.freeze

    def initialize(object_type, object_db_id)
      @object_type = object_type.to_sym
      @object_db_id = object_db_id
    end

    def execute
      raise NotImplementedError
    end

    private

    def upload_object?
      Gitlab::Geo::FileReplication.object_type_from_user_uploads?(object_type)
    end

    def job_artifact?
      object_type == :job_artifact
    end

    def service_klass_name
      return DEFAULT_KLASS_NAME if upload_object?

      object_type.to_s.camelize
    end

    def base_log_data(message)
      {
        class: self.class.name,
        object_type: object_type,
        object_db_id: object_db_id,
        message: message
      }
    end
  end
end
