# frozen_string_literal: true
class Packages::MavenPackageFinder
  attr_reader :path, :project

  def initialize(path, project = nil)
    @path = path
    @project = project
  end

  def execute
    packages.last
  end

  def execute!
    packages.last!
  end

  private

  def scope
    if project
      project.packages
    else
      ::Packages::Package.all
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def packages
    scope.joins(:maven_metadatum)
      .where(packages_maven_metadata: { path: path })
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
