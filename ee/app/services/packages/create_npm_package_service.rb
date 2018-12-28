# frozen_string_literal: true
module Packages
  class CreateNpmPackageService < BaseService
    def execute
      name = params[:name]
      version = params[:versions].keys.first
      version_data = params[:versions][version]

      package = project.packages.create!(
        name: name,
        version: version,
        package_type: 'npm'
      )

      package_file_name = "#{name}-#{version}.tgz"
      attachment = params['_attachments'][package_file_name]

      file_params = {
        file:      CarrierWaveStringFile.new(Base64.decode64(attachment['data'])),
        size:      attachment['length'],
        file_sha1: version_data[:dist][:shasum],
        file_name: package_file_name
      }

      ::Packages::CreatePackageFileService.new(package, file_params).execute

      package
    end
  end
end
