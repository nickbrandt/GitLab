# frozen_string_literal: true

class GroupDeletionSchedule < ApplicationRecord
  belongs_to :group
  belongs_to :deleting_user, foreign_key: 'user_id', class_name: 'User'
end
