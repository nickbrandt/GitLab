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
            client.delete_objects({ bucket: bucket_name, delete: { objects: objects } }) unless objects.empty?
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

      # Stores +file+ as +key+ in storage using multipart upload
      #
      # key: s3 key at which file is stored
      # file: An open file or file-like io object
      def multipart_upload(key, file)
        # AWS sdk v2 has upload_file which supports multipart
        # However Gitlab::HttpIO used when objectStorage is enabled
        # cannot be used with upload_file
        wrap_errors(key: key) do
          upload_id = client.create_multipart_upload({ bucket: bucket_name, key: key }).to_h[:upload_id]
          parts = upload_in_parts(key, file, upload_id)
          complete_multipart_upload(key, upload_id, parts)
        end
      # Rescue on Exception since even on keyboard inturrupt we want to abor the upload and re-raise
      rescue Exception => e # rubocop:disable Lint/RescueException
        abort_multipart_upload(key, upload_id)
        raise e
      end

      private

      attr_reader :client, :bucket_name

      def upload_in_parts(key, file, upload_id)
        parts = []
        part_number = 1
        part_size = 5.megabytes

        file.seek(0)
        until file.eof?
          part = client.upload_part({
            body: file.read(part_size),
            bucket: bucket_name,
            key: key,
            part_number: part_number, # required
            upload_id: upload_id
          })
          parts << part.to_h.merge(part_number: part_number)
          part_number += 1
        end
        file.seek(0)

        parts
      end

      def complete_multipart_upload(key, upload_id, parts)
        client.complete_multipart_upload({
          bucket: bucket_name,
          key: key,
          multipart_upload: {
            parts: parts
          },
          upload_id: upload_id
        })
      end

      def abort_multipart_upload(key, upload_id)
        if upload_id
          client.abort_multipart_upload(
            bucket: bucket_name,
            key: key,
            upload_id: upload_id
          )
        end
      end

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
