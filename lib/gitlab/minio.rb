# frozen_string_literal: true

module Gitlab
  class Minio
    class << self
      def port
        9009
      end

      def access_key
        'minio'
      end

      def secret_key
        'minio-secret'
      end

      def region
        'test'
      end

      def object_store_connection
        {
          provider: 'AWS',
          aws_access_key_id: access_key,
          aws_secret_access_key: secret_key,
          region: region,
          endpoint: "http://127.0.0.1:#{port}",
          path_style: true
        }
      end

      def live_url
        "http://127.0.0.1:#{port}/minio/health/live"
      end

      def uploader_classes
        ObjectSpace.each_object(Class).select do |klass|
          klass < ::ObjectStorage::Concern && klass.name
        end
      end
    end
  end
end
