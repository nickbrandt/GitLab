# frozen_string_literal: true

module Ci
  class BuildNeed < ApplicationRecord
    extend Gitlab::Ci::Model

    include BulkInsertSafe
    include IgnorableColumns

    ignore_columns :build_id_convert_to_bigint, remove_with: '14.1', remove_after: '2021-07-22'

    belongs_to :build, class_name: "Ci::Processable", foreign_key: :build_id, inverse_of: :needs

    validates :build, presence: true
    validates :name, presence: true, length: { maximum: 128 }
    validates :optional, inclusion: { in: [true, false] }

    scope :scoped_build, -> { where('ci_builds.id=ci_build_needs.build_id') }
    scope :artifacts, -> { where(artifacts: true) }

    def attributes
      super.except('build_id_convert_to_bigint')
    end
  end
end
