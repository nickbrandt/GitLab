# frozen_string_literal: true

module EE
  module API
    module Entities
      class LdapGroupLink < Grape::Entity
        expose :cn, :group_access, :provider
      end
    end
  end
end
