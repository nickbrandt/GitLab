# frozen_string_literal: true

class UserMention < ApplicationRecord
  self.abstract_class = true

  scope :user_ids, -> { select("unnest(mentioned_users_ids)").distinct }
  scope :group_ids, -> { select("unnest(mentioned_groups_ids)").distinct }
  scope :project_ids, -> { select("unnest(mentioned_projects_ids)").distinct }

  scope :for_note, ->(note) { where(note_id: note.id) }

  def mentioned_users
    User.where(id: mentioned_users_ids).distinct
  end

  def mentioned_groups
    Group.where(id: mentioned_groups_ids).distinct
  end

  def mentioned_projects
    Project.where(id: mentioned_projects_ids).distinct
  end

  def has_mentions?
    self.mentioned_users_ids.present? || self.mentioned_groups_ids.present? || self.mentioned_projects_ids.present?
  end
end
