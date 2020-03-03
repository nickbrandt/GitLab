# frozen_string_literal: true

module StatusPage
  module Storage
    # Implements a minimal AWS S3 client.
    class S3Client
      def initialize(region:, bucket_name:, access_key_id:, secret_access_key:)
        @bucket_name = bucket_name
        @client = Aws::S3::Client.new(
          region: region,
          credentials: Aws::Credentials.new(access_key_id, secret_access_key)
        )
      end

      # Stores +content+ as +key+ in storage
      #
      # Note: We are making sure that
      # * we control +content+ (not the user)
      # * this upload is done a background job (not in a web request)
      def upload_object(key, content)
        wrap_errors(key: key) do
          client.put_object(bucket: bucket_name, key: key, body: content)
        end

        true
      end

      private

      attr_reader :client, :bucket_name

      def wrap_errors(**args)
        yield
      rescue Aws::Errors::ServiceError => e
        raise Error, bucket: bucket_name, error: e, **args
      end
    end
  end
end
