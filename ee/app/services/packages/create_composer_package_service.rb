# frozen_string_literal: true
module Packages
  class CreateComposerPackageService < BaseService
    def execute
      body = JSON.parse(params)
      prepare_upload(body)
    end

    def prepare_upload(body)
      package = create_or_update_package(body)

      body['attachments'].each do |file|
        file_params = {
            file: CarrierWaveStringFile.new(Base64.decode64(file['contents'])),
            size: file['length'].to_i,
            file_sha1: body['version_data']['dist']['shasum'],
            file_name: file['filename']
        }

        ::Packages::CreatePackageFileService.new(package, file_params).execute
      end
    end

    def create_or_update_package(body)
      package_exists = project.packages.version_exists(body['name'], body['version'])

      package_exists.empty? ? create_package(body) : update_package(package_exists)
    end

    def create_package(body)
      project.packages.create!(
        name: body['name'],
        version: body['version'],
        package_type: 'composer'
      )
    end

    def update_package(package)
      package = package.first

      # This will remove 2 files and 2 associactions max
      package.package_files.destroy_all # rubocop:disable Cop/DestroyAll

      package
    end
  end
end
