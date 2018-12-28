# frozen_string_literal: true

class NpmPackagePresenter
  include API::Helpers::RelatedResourcesHelpers

  attr_reader :project, :name, :packages

  def initialize(project, name, packages)
    @project = project
    @name = name
    @packages = packages
  end

  def versions
    package_versions = {}

    packages.each do |package|
      package_file = package.package_files.last

      next unless package_file

      package_versions[package.version] = build_package_version(package, package_file)
    end

    package_versions
  end

  private

  def build_package_version(package, package_file)
    {
      "name": package.name,
      "version": package.version,
      "dist": {
        "shasum": package_file.file_sha1,
        "tarball": tarball_url(package, package_file)
      }
    }
  end

  def tarball_url(package, package_file)
    expose_url "#{api_v4_projects_path(id: package.project_id)}" \
      "/packages/npm/#{package.name}" \
      "/-/#{package_file.file_name}"
  end
end
