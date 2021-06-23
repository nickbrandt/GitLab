# frozen_string_literal: true

module QualityManagement
  module TestCases
    class CreateService < BaseService
      ISSUE_TYPE = 'test_case'

      def initialize(project, current_user, title:, description: nil, label_ids: [])
        super(project, current_user)

        @title = title
        @description = description
        @label_ids = label_ids
      end

      def execute
        issue = Issues::CreateService.new(
          project: project,
          current_user: current_user,
          params: {
            issue_type: ISSUE_TYPE,
            title: title,
            description: description,
            label_ids: label_ids
          },
          spam_params: nil
        ).execute

        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        success(issue)
      end

      private

      attr_reader :title, :description, :label_ids

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
