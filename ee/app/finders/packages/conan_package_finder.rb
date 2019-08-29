# frozen_string_literal: true
class Packages::ConanPackageFinder
  attr_reader :recipe, :current_user, :project

  def initialize(recipe, current_user, project: nil)
    @recipe = recipe
    @current_user = current_user
    @project = project
  end

  def execute
    return unless project

    project.packages.last
  end
end
