# frozen_string_literal: true

module EE
  module ProtectedBranches
    module ApiService
      extend ::Gitlab::Utils::Override

      override :protected_branch_params
      def protected_branch_params
        super.tap do |hash|
          hash[:unprotect_access_levels_attributes] = ::ProtectedBranches::AccessLevelParams.new(:unprotect, params).access_levels
        end
      end
    end
  end
end
