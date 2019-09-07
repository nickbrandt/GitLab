# frozen_string_literal: true
class ComposerPackagePresenter
  attr_reader :packages

  COMPOSER_JSON_SUFFIX = %r{.json$}.freeze
  COMPOSER_ARCHIVE_SUFFIX = %r{.(zip|tar)$}.freeze

  def initialize(packages)
    @packages = packages
  end

  def versions
    default_branches = {}

    package_versions = packages.each_with_object({}) do |package, package_versions|
      default_branches[package.name] = package.project.default_branch
      package_versions[package[:name]] ||= {}

      package_versions[package[:name]].store(package.version, build_package_version(package))
    end

    packages_versions_latest = abandoned_root_packages(package_versions, default_branches)
    packages = abandon(package_versions, packages_versions_latest)

    { "packages" => packages }
  end

  def packages_root(sha)
    { "packages" => [], "includes" => { "include/all$#{sha}.json" => { "sha1" => sha } } }
  end

  def same_sha?(sha)
    sha == Digest::SHA1.hexdigest(versions.to_json)
  end

  private

  def abandon(package_versions, packages_versions_latest)
    package_versions.each do |package|
      abandoned = package_versions[package[0]][packages_versions_latest[package[0]]]['abandoned']

      unless abandoned.blank?
        package[1].each do |version|
          version[1]['abandoned'] = abandoned
        end
      end
    end
  end

  def abandoned_root_packages(package_versions, default_branches)
    abandoned = {}

    package_versions.each do |package|
      versions = package[1].keys
      default_branch = default_branches["#{package[0]}"]

      # Determine which package version to use for setting a package 'abandoned'
      if versions.include?("dev-#{default_branch}")
        root_version = "dev-#{default_branch}"
      else
        versions_number = versions.grep(/^(v)?([0-9]{1,2}[.][0-9]{1,2}[.][0-9]{1,2}$)/)
        versions_number_sorted = versions_number.sort_by {|s| s.match(/^(v)?([0-9]{1,2}[.][0-9]{1,2}[,.][0-9]{1,2}$)/).captures[1]}
        root_version = versions_number_sorted.last
      end

      abandoned[package[0]] = root_version
    end

    abandoned
  end

  def build_package_version(package)
    json = json_file(package.package_files)

    unless json.blank?
      composer_file = "#{Gitlab.config.packages.storage_path}#{json.file}"

      # Get first version in JSON metadata file of a package, because this file contains only a single version
      composer_json_content = JSON.parse(File.read(composer_file)).first[1]

      composer_json_content = rewrite_urls(package, composer_json_content)
      composer_json_content
    end
  end

  def rewrite_urls(package, json)
    archive = archive_file(package.package_files)

    json['source']['url'] = package.project.http_url_to_repo
    json['dist']['url'] = "#{Gitlab.config.gitlab.url}/api/v4/projects/#{package.project.id}/packages/composer/#{package.name}/-/#{archive.file_name}"
    json
  end

  def json_file(files)
    files.find {|element| element[:file_name].match(COMPOSER_JSON_SUFFIX)}
  end

  def archive_file(files)
    files.find {|element| element[:file_name].match(COMPOSER_ARCHIVE_SUFFIX)}
  end
end
