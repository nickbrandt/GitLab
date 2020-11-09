# frozen_string_literal: true

module EE
  module JiraService
    extend ActiveSupport::Concern

    prepended do
      validates :project_key, presence: true, if: :issues_enabled
      validates :vulnerabilities_issuetype, presence: true, if: :vulnerabilities_enabled
    end

    def issuetypes
      return [] unless vulnerabilities_enabled

      client
        .Issuetype
        .all
        .select { |issuetype| !issuetype.subtask }
        .map { |issuetype| { id: issuetype.id, name: issuetype.name, description: issuetype.description } }
    end

    def test(_)
      super
        .then { |result| result[:success] ? result.merge(data: { issuetypes: issuetypes }) : result }
    end
  end
end
