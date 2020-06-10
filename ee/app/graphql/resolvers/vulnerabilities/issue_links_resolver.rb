# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class IssueLinksResolver < BaseResolver
      type Types::Vulnerability::IssueLinkType, null: true

      argument :link_type, Types::Vulnerability::IssueLinkTypeEnum,
               required: false,
               description: 'Filter issue links by link type'

      delegate :issue_links, to: :object, private: true

      def resolve(link_type: nil, **)
        issue_links.by_link_type(link_type)
      end
    end
  end
end
