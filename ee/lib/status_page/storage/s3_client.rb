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
      # * this upload is done as a background job (not in a web request)
      def upload_object(key, content)
        wrap_errors(key: key) do
          client.put_object(bucket: bucket_name, key: key, body: content)
        end

        true
      end

      # Deletes object at +key+ from storage
      #
      # Note, this operation succeeds even if +key+ does not exist in storage.
      def delete_object(key)
        wrap_errors(key: key) do
          client.delete_object(bucket: bucket_name, key: key)
        end

        true
      end

      # Delete all objects whose key has a given +prefix+
      def recursive_delete(prefix)
        wrap_errors(prefix: prefix) do
          # Aws::S3::Types::ListObjectsV2Output is paginated and Enumerable
          list_objects(prefix).each.with_index do |response, index|
            break if index >= StatusPage::Storage::MAX_PAGES

            objects = response.contents.map { |obj| { key: obj.key } }
            # Batch delete in sets determined by default max_key argument that can be passed to list_objects_v2
            client.delete_objects({ bucket: bucket_name, delete: { objects: objects } })
          end
        end

        true
      end

      # Return a Set of all keys with a given prefix
      def list_object_keys(prefix)
        wrap_errors(prefix: prefix) do
          list_objects(prefix).reduce(Set.new) do |objects, (response, index)|
            break objects if objects.size >= StatusPage::Storage::MAX_IMAGE_UPLOADS

            objects | response.contents.map(&:key)
          end
        end
      end

      private

      attr_reader :client, :bucket_name

      def list_objects(prefix)
        client.list_objects_v2(bucket: bucket_name, prefix: prefix, max_keys: StatusPage::Storage::MAX_KEYS_PER_PAGE)
      end

      def wrap_errors(**args)
        yield
      rescue Aws::Errors::ServiceError => e
        raise Error, bucket: bucket_name, error: e, **args
      end
    end
  end
end
