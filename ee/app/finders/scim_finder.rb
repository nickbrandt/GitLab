# frozen_string_literal: true

class ScimFinder
  attr_reader :saml_provider

  def initialize(group)
    @saml_provider = group&.saml_provider
  end

  def search(params)
    return Identity.none unless saml_provider&.enabled?

    parsed_hash = EE::Gitlab::Scim::ParamsParser.new(params).result
    Identity.where_group_saml_uid(saml_provider, parsed_hash[:extern_uid])
  end
end
