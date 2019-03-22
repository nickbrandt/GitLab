# frozen_string_literal: true

module DependencyProxy
  class FindOrCreateBlobService < DependencyProxy::BaseService
    def initialize(group, image, token, blob_sha)
      @group = group
      @image = image
      @token = token
      @blob_sha = blob_sha
    end

    def execute
      file_name = @blob_sha.sub('sha256:', '') + '.gz'
      blob = @group.dependency_proxy_blobs.find_or_build(file_name)

      unless blob.persisted?
        temp_file = Tempfile.new

        success = DependencyProxy::DownloadBlobService
          .new(@image, @blob_sha, @token, temp_file.path).execute

        return unless success

        blob.file = temp_file
        blob.size = temp_file.size
        blob.save!
      end

      blob
    end
  end
end
