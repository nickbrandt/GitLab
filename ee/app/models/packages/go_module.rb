# frozen_string_literal: true

class Packages::GoModule
  attr_reader :project, :name, :path

  def initialize(project, name)
    @project = project
    @name = name

    @path =
      if @name == package_base
        ''
      elsif @name.start_with?(package_base + '/')
        @name[(package_base.length + 1)..]
      else
        nil
      end
  end

  def versions
    @versions ||= @project.repository.tags
      .filter { |tag| ::Packages::GoModuleVersion.semver? tag }
      .map    { |tag| ::Packages::GoModuleVersion.new self, tag }
      .filter { |ver| ver.valid? }
  end

  def find_version(name)
    if ::Packages::GoModuleVersion.pseudo_version? name
      begin
        ::Packages::GoModuleVersion.new self, name
      rescue ArgumentError
        nil
      end
    else
      versions.filter { |ver| ver.name == name }.first
    end
  end

  private

  def package_base
    @package_base ||= Gitlab::Routing.url_helpers.project_url(@project).split('://', 2)[1]
  end
end
