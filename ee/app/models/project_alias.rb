# frozen_string_literal: true

class ProjectAlias < ApplicationRecord
  belongs_to :project

  validates :project, presence: true
  validates :name, presence: true, uniqueness: true
end
