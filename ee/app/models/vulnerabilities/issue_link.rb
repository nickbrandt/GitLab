# frozen_string_literal: true

module Vulnerabilities
  class IssueLink < ApplicationRecord
    self.table_name = 'vulnerability_issue_links'

    belongs_to :vulnerability
    belongs_to :issue

    enum link_type: { related: 1, created: 2 } # 'related' is the default value

    validates :vulnerability, :issue, presence: true
  end
end
