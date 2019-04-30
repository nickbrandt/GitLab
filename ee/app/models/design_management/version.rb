# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include ShaAttribute

    has_and_belongs_to_many :designs,
                            class_name: "DesignManagement::Design",
                            inverse_of: :versions

    # This is a polymorphic association, so we can't count on FK's to delete the
    # data
    has_many :notes, as: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    validates :sha, presence: true
    validates :sha, uniqueness: { case_sensitive: false }

    sha_attribute :sha
  end
end
