# frozen_string_literal: true

module Integrations
  module Jira
    class IssueSerializer < BaseSerializer
      entity ::Integrations::Jira::IssueEntity
    end
  end
end
