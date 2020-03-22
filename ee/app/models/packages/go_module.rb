# frozen_string_literal: true

class Packages::GoModule #< ApplicationRecord
  SEMVER_TAG_REGEX = Regexp.new("^#{::Packages::GoModuleVersion::SEMVER_REGEX.source}$").freeze

  # belongs_to :project

  attr_reader :project, :name, :path, :versions

  def initialize(project, name)
    @project = project
    @name = name

    @path =
      if @name == package_base
        ''
      elsif @name.start_with?(package_base + '/')
        @name[(package_base.length+1)..]
      else
        nil
      end
  end

  def versions
    @versions ||= project.repository.tags.
      filter { |tag| SEMVER_TAG_REGEX.match?(tag.name) && !tag.dereferenced_target.nil? }.
      map    { |tag| ::Packages::GoModuleVersion.new self, tag }.
      filter { |ver| ver.valid? }
  end

  def find_version(name)
    versions.filter { |ver| ver.name == name }.first
  end

  private

  def package_base
    @package_base ||= Gitlab::Routing.url_helpers.project_url(@project).split('://', 2)[1]
  end
end
