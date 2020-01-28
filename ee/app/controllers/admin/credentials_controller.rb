# frozen_string_literal: true

class Admin::CredentialsController < Admin::ApplicationController
  include CredentialsInventoryActions

  helper_method :credentials_inventory_path, :user_detail_path

  private

  def credentials_inventory_path(args)
    admin_credentials_path(args)
  end

  def user_detail_path(user)
    admin_user_path(user)
  end

  def user
    nil
  end
end
