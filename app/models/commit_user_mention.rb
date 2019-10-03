# frozen_string_literal: true

class CommitUserMention < UserMention
  belongs_to :note, inverse_of: :commit_user_mentions
end
