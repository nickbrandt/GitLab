# frozen_string_literal: true

class Requirement < ApplicationRecord
  include CacheMarkdownField
  include StripAttribute
  include AtomicInternalId
  include Sortable

  cache_markdown_field :title, pipeline: :single_line

  strip_attributes :title

  belongs_to :author, class_name: 'User'
  belongs_to :project

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
