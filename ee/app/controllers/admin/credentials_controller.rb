# frozen_string_literal: true

class Admin::CredentialsController < Admin::ApplicationController
  extend ::Gitlab::Utils::Override
  include CredentialsInventoryActions

  helper_method :credentials_inventory_path, :user_detail_path

  before_action :check_license_credentials_inventory_available!, only: [:index]

  private

  def check_license_credentials_inventory_available!
    render_404 unless credentials_inventory_feature_available?
  end

  override :credentials_inventory_path
  def credentials_inventory_path(args)
    admin_credentials_path(args)
  end

  override :user_detail_path
  def user_detail_path(user)
    admin_user_path(user)
  end

  override :users
  def users
    nil
  end
end
