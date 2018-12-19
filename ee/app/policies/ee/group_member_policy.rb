# frozen_string_literal: true

module EE
  module GroupMemberPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:ldap, score: 0) { @subject.ldap? }
      condition(:override, score: 0) { @subject.override? }

      rule { ~ldap }.prevent :override_group_member
      rule { ldap & ~override }.prevent :update_group_member
    end
  end
end
