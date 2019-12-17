# frozen_string_literal: true

class Admin::CredentialsController < Admin::ApplicationController
  include Admin::CredentialsHelper

  before_action :check_license_credentials_inventory_available!

  def index
    @credentials = filter_credentials.page(params[:page]).preload_users.without_count
  end

  private

  def filter_credentials
    if show_personal_access_tokens?
      ::PersonalAccessTokensFinder.new({ user: nil, impersonation: false, state: 'active', sort: 'id_desc' }).execute
    elsif show_ssh_keys?
      ::KeysFinder.new(current_user, { user: nil, key_type: 'ssh' }).execute
    end
  end

  def check_license_credentials_inventory_available!
    render_404 unless credentials_inventory_feature_available?
  end
end
