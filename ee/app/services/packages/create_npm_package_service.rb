# frozen_string_literal: true
module Packages
  class CreateNpmPackageService < BaseService
    def execute
      name = params[:name]
      version = params[:versions].keys.first
      version_data = params[:versions][version]
      build = params[:build]

      existing_package = project.packages.npm.with_name(name).with_version(version)

      return error('Package already exists.', 403) if existing_package.exists?

      package = project.packages.create!(
        name: name,
        version: version,
        package_type: 'npm'
      )

      if build.present?
        package.create_build_info!(pipeline: build.pipeline)
      end

      package_file_name = "#{name}-#{version}.tgz"
      attachment = params['_attachments'][package_file_name]

      file_params = {
        file:      CarrierWaveStringFile.new(Base64.decode64(attachment['data'])),
        size:      attachment['length'],
        file_sha1: version_data[:dist][:shasum],
        file_name: package_file_name
      }

      package.transaction do
        ::Packages::CreatePackageFileService.new(package, file_params).execute
        ::Packages::CreateDependencyService.new(package, package_dependencies).execute
      end

      package
    end

    def package_dependencies
      _version, version_data = params[:versions].first
      version_data
    end
  end
end
