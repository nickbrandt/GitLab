# frozen_string_literal: true

module DependencyProxy
  class DownloadBlobService < DependencyProxy::BaseService
    DownloadError = Class.new(StandardError)

    def initialize(image, blob_sha, token, file_path)
      @image = image
      @blob_sha = blob_sha
      @token = token
      @file_path = file_path
    end

    def execute
      File.open(@file_path, "wb") do |file|
        Gitlab::HTTP.get(blob_url, headers: auth_headers, stream_body: true) do |fragment|
          if [301, 302, 307].include?(fragment.code)
            # do nothing
          elsif fragment.code == 200
            file.write(fragment)
          else
            raise DownloadError, "Non-success status code while downloading a blob. #{fragment.code}"
          end
        end
      end

      true
    rescue DownloadError
      false
    end

    private

    def blob_url
      registry.blob_url(@image, @blob_sha)
    end
  end
end
