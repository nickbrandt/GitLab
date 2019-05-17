# frozen_string_literal: true
class ComposerPackagePresenter
  attr_reader :packages

  COMPOSER_JSON_SUFFIX = /.json$/

  def initialize(packages)
    @packages = packages
  end

  def versions
    package_versions = packages.each_with_object({}) do |package, package_versions|
      package_versions[package[:name]] ||= {}
      package_versions[package[:name]].store(package.version, build_package_version(package))
    end

    { "packages" => package_versions }
  end

  def packages_root(sha)
    { "packages" => [], "includes" => { "include/all$#{sha}.json" => { "sha1" => sha } } }
  end

  def same_sha?(sha)
    sha == Digest::SHA1.hexdigest(versions.to_json)
  end

  private

  def build_package_version(package)
    json = json_file(package.package_files)

    unless json.blank?
      composer_file = "#{Gitlab.config.packages.storage_path}#{json.file}"

      # Get first version in JSON metadata file of a package, because this file contains only a single version
      JSON.parse(File.read(composer_file)).first[1]
    end
  end

  def json_file(files)
    files.find {|element| COMPOSER_JSON_SUFFIX.match(element[:file_name])}
  end
end
