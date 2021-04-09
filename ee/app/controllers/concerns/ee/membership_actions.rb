# frozen_string_literal: true

module EE
  module MembershipActions
    extend ::Gitlab::Utils::Override

    override :leave
    def leave
      super

      if membershipable == current_user.provisioned_by_group && current_user.authorized_by_provisioned_by_group?
        sign_out current_user
      end
    end
  end
end
