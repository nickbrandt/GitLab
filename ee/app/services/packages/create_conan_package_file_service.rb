# frozen_string_literal: true
module Packages
  class CreateConanPackageFileService
    attr_reader :package, :params

    def initialize(package, params)
      @package = package
      @params = params
    end

    def execute
      # Revision is hardcoded to '0' per v1 implementation of Conan API
      package.package_files.create!(
        file:      params[:file],
        size:      params[:size],
        file_name: params[:file_name],
        file_type: params[:file_type],
        file_sha1: params[:file_sha1],
        file_md5:  params[:file_md5],
        conan_file_metadatum_attributes: {
          path: params[:path],
          recipe: params[:recipe],
          revision: '0'
        }
      )
    end
  end
end
