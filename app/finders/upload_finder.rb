# frozen_string_literal: true

class UploadFinder
  def initialize(project, secret, file_path)
    @project = project
    @secret = secret
    @file_path = file_path
  end

  def execute
    Gitlab::Utils.check_path_traversal!(@file_path)
    uploader = FileUploader.new(@project, secret: @secret)
    uploader.retrieve_from_store!(@file_path)

    uploader
  end
end
