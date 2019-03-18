# frozen_string_literal: true

class ProjectSnippet < Snippet
  belongs_to :project

  validates :project, presence: true
  validates :visibility_level, exclusion: { in: [Gitlab::VisibilityLevel::SECRET] }
end
