# frozen_string_literal: true

module EE
  module UsersFinder
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      by_non_ldap(super)
    end

    def by_non_ldap(users)
      return users unless params[:skip_ldap]

      users.non_ldap
    end
  end
end
