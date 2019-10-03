# frozen_string_literal: true

class IssueUserMention < UserMention
  belongs_to :issue
  belongs_to :note, inverse_of: :issue_user_mentions
end
