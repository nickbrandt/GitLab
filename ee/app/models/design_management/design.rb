# frozen_string_literal: true

module DesignManagement
  class Design < ApplicationRecord
    belongs_to :project
    belongs_to :issue
    has_many :versions, class_name: 'DesignManagement::Version', inverse_of: :design

    validates :project, :issue, :filename, presence: true
    validates :issue, uniqueness: true
    validates :filename, uniqueness: { scope: :issue_id }
  end
end
