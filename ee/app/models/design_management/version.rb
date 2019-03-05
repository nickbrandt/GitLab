# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include ShaAttribute

    belongs_to :design, class_name: "DesignManagement::Design", foreign_key: 'design_management_design_id'
    has_one :project, through: :design
    has_one :issue, through: :design

    # This is a polymorphic association, so we can't count on FK's to delete the
    # data
    has_many :notes, as: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    validates :sha, :design, presence: true
    validates :sha, uniqueness: { case_sensitive: false }

    sha_attribute :sha
  end
end
