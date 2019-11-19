# frozen_string_literal: true

module EE
  module DescriptionVersion
    extend ActiveSupport::Concern

    prepended do
      belongs_to :epic
    end

    class_methods do
      def issuable_attrs
        (super + %i(epic)).freeze
      end
    end

    def issuable
      epic || super
    end

    def previous_version
      self.class.where(
        issue_id: issue_id,
        merge_request_id: merge_request_id,
        epic_id: epic_id
      ).where('created_at < ?', created_at)
      .order(created_at: :desc, id: :desc)
      .first
    end
  end
end
