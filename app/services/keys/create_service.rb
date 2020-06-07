# frozen_string_literal: true

module Keys
  class CreateService < ::Keys::BaseService
    def initialize(current_user, params = {})
      @current_user, @params, @user = current_user, params, params.delete(:user)
      @ip_address = @params.delete(:ip_address)
    end

    def execute
      key = user.keys.create(params)
      notification_service.new_key(key) if key.persisted?
      key
    end
  end
end

Keys::CreateService.prepend_if_ee('EE::Keys::CreateService')
