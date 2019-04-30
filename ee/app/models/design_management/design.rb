# frozen_string_literal: true

module DesignManagement
  class Design < ApplicationRecord
    belongs_to :project
    belongs_to :issue
    has_and_belongs_to_many :versions, class_name: 'DesignManagement::Version', inverse_of: :designs

    validates :project, :issue, :filename, presence: true
    validates :filename, uniqueness: { scope: :issue_id }
  end
end
