# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateService
      extend ::Gitlab::Utils::Override

      override :after_create
      def after_create(issuable)
        super

        issuable.sync_code_owners_with_approvers
      end
    end
  end
end
