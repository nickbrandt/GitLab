# frozen_string_literal: true

module EE
  module MergeRequests
    module PostMergeService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        super
        ApprovalRules::FinalizeService.new(merge_request).execute
      end
    end
  end
end
