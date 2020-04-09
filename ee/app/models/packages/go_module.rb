# frozen_string_literal: true

class Packages::GoModule
  attr_reader :project, :name, :path

  def initialize(project, name, path)
    @project = project
    @name = name
    @path = path
  end

  def versions
    @versions ||= Packages::Go::VersionFinder.new(self).execute
  end

  def find_version(name)
    Packages::Go::VersionFinder.new(self).find(name)
  end

  def path_valid?(major)
    m = /\/v(\d+)$/i.match(@name)

    case major
    when 0, 1
      m.nil?
    else
      !m.nil? && m[1].to_i == major
    end
  end

  def gomod_valid?(gomod)
    gomod&.split("\n", 2)&.first == "module #{@name}"
  end
end
