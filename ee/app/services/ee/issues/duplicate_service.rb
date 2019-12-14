# frozen_string_literal: true

module EE
  module Issues
    module DuplicateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(duplicate_issue, canonical_issue)
        super

        relate_two_issues(duplicate_issue, canonical_issue)
      end

      private

      def relate_two_issues(duplicate_issue, canonical_issue)
        params = { target_issuable: canonical_issue }
        IssueLinks::CreateService.new(duplicate_issue, current_user, params).execute
      end
    end
  end
end
