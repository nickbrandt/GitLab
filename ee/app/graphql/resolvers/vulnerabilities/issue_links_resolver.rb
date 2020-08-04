# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class IssueLinksResolver < BaseResolver
      type Types::Vulnerability::IssueLinkType, null: true

      argument :link_type, Types::Vulnerability::IssueLinkTypeEnum,
               required: false,
               description: 'Filter issue links by link type'

      delegate :issue_links, :finding, to: :object, private: true

      def resolve(link_type: nil, **)
        links = issue_links.by_link_type(link_type)
        return links if links.present? || link_type != 'created'

        issue_feedback = finding.issue_feedback
        return [] if issue_feedback.blank?

        issue_links.build(issue_id: issue_feedback.id, link_type: :created)
      end
    end
  end
end
