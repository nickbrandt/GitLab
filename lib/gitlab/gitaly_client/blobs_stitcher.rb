# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class BlobsStitcher
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        current_blob_data = nil

        @binary_check_buffer = {}
        @rpc_response.each do |msg|
          if msg.oid.blank? && msg.data.blank?
            next
          elsif msg.oid.present?
            yield new_blob(current_blob_data) if current_blob_data

            current_blob_data = msg.to_h.slice(:oid, :path, :size, :revision, :mode)
            current_blob_data[:data_parts] = [msg.data]
          else
            current_blob_data[:data_parts] << msg.data
          end
        end

        yield new_blob(current_blob_data) if current_blob_data
      end

      private

      def new_blob(blob_data)
        data = blob_data[:data_parts].join
        path = blob_data[:path]

        Gitlab::Git::Blob.new(
          id: blob_data[:oid],
          mode: blob_data[:mode].to_s(8),
          name: File.basename(path),
          path: path,
          size: blob_data[:size],
          commit_id: blob_data[:revision],
          data: data,
          binary: binary_by_path?(path, data)
        )
      end

      def binary_by_path?(path, blob_data)
        return @binary_check_buffer[path] if @binary_check_buffer.key?(path)

        @binary_check_buffer[path] = Gitlab::Git::Blob.binary?(blob_data)
      end
    end
  end
end
