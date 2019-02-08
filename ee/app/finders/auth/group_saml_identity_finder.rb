# frozen_string_literal: true

module Auth
  class GroupSamlIdentityFinder
    attr_reader :saml_provider, :auth_hash

    def initialize(saml_provider, auth_hash)
      @saml_provider = saml_provider
      @auth_hash = auth_hash
    end

    def first
      Identity.find_by_group_saml_uid(saml_provider, uid)
    end

    private

    def uid
      auth_hash.uid
    end
  end
end
