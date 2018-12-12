# frozen_string_literal: true

module EE
  module Event
    extend ActiveSupport::Concern

    prepended do
      scope :issues, -> { where(target_type: 'Issue') }
      scope :merge_requests, -> { where(target_type: 'MergeRequest') }
      scope :created, -> { where(action: ::Event::CREATED) }
      scope :closed, -> { where(action: ::Event::CLOSED) }
      scope :merged, -> { where(action: ::Event::MERGED) }
      scope :totals_by_author, -> { group(:author_id).count }
    end
  end
end
