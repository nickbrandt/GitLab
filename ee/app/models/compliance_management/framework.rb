# frozen_string_literal: true

module ComplianceManagement
  class Framework < ApplicationRecord
    self.table_name = 'compliance_management_frameworks'

    before_validation :strip_whitespace_from_attrs

    validates :name, presence: true, length: { maximum: 255 }
    validates :description, presence: true, length: { maximum: 255 }
    validates :color, color: true, allow_blank: false, length: { maximum: 7 }

    def display_name
      "#{name} - #{description}"
    end

    private

    def strip_whitespace_from_attrs
      %w(color name).each { |attr| self[attr] = self[attr]&.strip }
    end
  end
end
