# frozen_string_literal: true

module Registrations
  class GroupsController < ApplicationController
    layout 'checkout'

    before_action :authorize_create_group!, only: :new

    def new
      @group = Group.new
    end

    def create
      @group = Groups::CreateService.new(current_user, group_params).execute

      if @group.persisted?
        redirect_to @group
      else
        render action: :new
      end
    end

    private

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def group_params
      params.require(:group).permit(:name, :path, :visibility_level)
    end
  end
end
