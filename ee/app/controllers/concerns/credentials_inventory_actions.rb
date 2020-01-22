# frozen_string_literal: true

module CredentialsInventoryActions
  extend ActiveSupport::Concern
  include CredentialsInventoryHelper

  included do
    before_action :check_license_credentials_inventory_available!, only: [:index]
  end

  def index
    @credentials = filter_credentials.page(params[:page]).preload_users.without_count # rubocop:disable Gitlab/ModuleWithInstanceVariables

    render 'shared/credentials_inventory/index'
  end

  private

  def filter_credentials
    if show_personal_access_tokens?
      ::PersonalAccessTokensFinder.new({ user: user, impersonation: false, state: 'active', sort: 'id_desc' }).execute
    elsif show_ssh_keys?
      ::KeysFinder.new(current_user, { user: user, key_type: 'ssh' }).execute
    end
  end

  def check_license_credentials_inventory_available!
    render_404 unless credentials_inventory_feature_available?
  end

  def user
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
