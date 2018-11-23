# frozen_string_literal: true

class ProjectRepository < ActiveRecord::Base
  include RepositoryOnShard

  belongs_to :project

  class << self
    def find_project(disk_path)
      find_by(disk_path: disk_path)&.project
    end
  end
end
