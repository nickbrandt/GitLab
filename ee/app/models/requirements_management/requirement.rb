# frozen_string_literal: true

module RequirementsManagement
  class Requirement < ApplicationRecord
    include CacheMarkdownField
    include StripAttribute
    include AtomicInternalId
    include Sortable

    # the expected name for this table is `requirements_management_requirements`,
    # but to avoid downtime and deployment issues `requirements` is still used
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30052#note_329556542
    self.table_name = 'requirements'

    cache_markdown_field :title, pipeline: :single_line

    strip_attributes :title

    belongs_to :author, inverse_of: :requirements, class_name: 'User'
    belongs_to :project, inverse_of: :requirements

    has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.requirements&.maximum(:iid) }

    validates :author, :project, :title, presence: true

    validates :title, length: { maximum: Issuable::TITLE_LENGTH_MAX }
    validates :title_html, length: { maximum: Issuable::TITLE_HTML_LENGTH_MAX }, allow_blank: true

    enum state: { opened: 1, archived: 2 }

    scope :for_iid, -> (iid) { where(iid: iid) }
    scope :for_state, -> (state) { where(state: state) }
    scope :counts_by_state, -> { group(:state).count }

    def self.simple_sorts
      super.except('name_asc', 'name_desc')
    end

    # In the next iteration we will support also group-level requirements
    # so it's better to use resource_parent instead of project directly
    def resource_parent
      project
    end
  end
end
