# frozen_string_literal: true

class Projects::FeatureFlagsUserListsController < Projects::ApplicationController
  before_action :check_feature_flag!
  before_action :authorize_admin_feature_flags_user_lists!
  before_action :user_list, only: [:edit, :show]

  def new
  end

  def edit
  end

  def show
  end

  private

  def check_feature_flag!
    not_found unless Feature.enabled?(:feature_flag_user_lists, project)
  end

  def user_list
    @user_list = project.operations_feature_flags_user_lists.find_by_iid!(params[:iid])
  end
end
