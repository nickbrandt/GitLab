# frozen_string_literal: true

module GpgKeys
  class CreateService < Keys::BaseService
    attr_accessor :current_user

    def initialize(current_user, params = {})
      @current_user, @params = current_user, params
      @ip_address = @params.delete(:ip_address)
      @user = params.delete(:user) || current_user
    end

    def execute
      key = user.gpg_keys.create(params)
      notification_service.new_gpg_key(key) if key.persisted?
      key
    end
  end
end
