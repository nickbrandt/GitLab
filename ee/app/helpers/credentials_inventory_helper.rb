# frozen_string_literal: true

module CredentialsInventoryHelper
  VALID_FILTERS = %w(ssh_keys personal_access_tokens).freeze

  def show_personal_access_tokens?
    return true if params[:filter] == 'personal_access_tokens'

    VALID_FILTERS.exclude? params[:filter]
  end

  def show_ssh_keys?
    params[:filter] == 'ssh_keys'
  end

  def credentials_inventory_feature_available?
    License.feature_available?(:credentials_inventory)
  end

  def credentials_inventory_path(args)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def user_detail_path(user)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
