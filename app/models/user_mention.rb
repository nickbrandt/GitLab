# frozen_string_literal: true

class UserMention < ApplicationRecord
  self.abstract_class = true

  belongs_to :mentioned_user, foreign_key: :mentioned_user_id, class_name: 'User'
  belongs_to :mentioned_project, foreign_key: :mentioned_project_id, class_name: 'Project'
  belongs_to :mentioned_group, foreign_key: :mentioned_group_id, class_name: 'Group'
end
