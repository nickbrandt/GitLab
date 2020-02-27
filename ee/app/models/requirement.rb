# frozen_string_literal: true

class Requirement < ApplicationRecord
  include CacheMarkdownField

  cache_markdown_field :title, pipeline: :single_line

  belongs_to :author, class_name: 'User'
  belongs_to :project

  validates :author, :project, :title, presence: true

  validates :title, length: { maximum: Issuable::TITLE_LENGTH_MAX }
  validates :title_html, length: { maximum: Issuable::TITLE_HTML_LENGTH_MAX }, allow_blank: true

  enum state: { opened: 1, archived: 2 }

  # In the next iteration we will support also group-level requirements
  # so it use resource_parent instead of project directly
  def resource_parent
    project
  end
end
