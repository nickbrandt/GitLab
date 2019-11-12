# frozen_string_literal: true

class UserMention < ApplicationRecord
  include FromUnion

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
    mentioned_ids_present? && mentions_exist?
  end

  private

  def mentioned_ids_present?
    mentioned_users_ids.present? || mentioned_groups_ids.present? || mentioned_projects_ids.present?
  end

  def mentions_exist?
    (self.mentioned_users.exists? || self.mentioned_groups.exists? || self.mentioned_projects.exists?)
  end
end
