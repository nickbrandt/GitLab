# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateService
      extend ::Gitlab::Utils::Override

      override :after_create
      def after_create(issuable)
        super

        ::MergeRequests::SyncCodeOwnerApprovalRules.new(issuable).execute
      end
    end
  end
end
