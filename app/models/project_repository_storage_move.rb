# frozen_string_literal: true

# ProjectRepositoryStorageMove are details of repository storage moves for a
# project. For example, moving a project to another gitaly node to help
# balance storage capacity.
class ProjectRepositoryStorageMove < ApplicationRecord
  belongs_to :project, inverse_of: :repository_storage_moves

  enum state: { scheduled: 1, started: 2, finished: 3, failed: 4 }

  validates :project, presence: true
  validates :state, presence: true
  validates :source_storage_name,
    presence: true,
    inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
  validates :destination_storage_name,
    presence: true,
    inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
end
