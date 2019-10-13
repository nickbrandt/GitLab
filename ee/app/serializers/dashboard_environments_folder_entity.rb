# frozen_string_literal: true

class DashboardEnvironmentsFolderEntity < Grape::Entity
  expose :last_environment, merge: true, using: DashboardEnvironmentEntity
  expose :size
  expose :within_folder?, as: :within_folder
end
