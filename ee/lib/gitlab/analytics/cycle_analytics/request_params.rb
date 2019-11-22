# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RequestParams
        include ActiveModel::Model
        include ActiveModel::Validations
        include ActiveModel::Attributes

        attr_writer :project_ids

        attribute :created_after, :date
        attribute :created_before, :date

        validates :created_after, presence: true
        validates :created_before, presence: true

        validate :validate_created_before

        def project_ids
          Array(@project_ids)
        end

        private

        def validate_created_before
          return if created_after.nil? || created_before.nil?

          errors.add(:created_before, :invalid) if created_after > created_before
        end
      end
    end
  end
end
