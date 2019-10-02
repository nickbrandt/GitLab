# frozen_string_literal: true

module Users
  class SignupService < BaseService
    attr_reader :user

    def initialize(current_user, params = {})
      @current_user = current_user
      @user = params.delete(:user)
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      assign_attributes
      custom_validations

      if @user.errors.empty? && @user.save(validate: validate)
        success
      else
        messages = @user.errors.full_messages + Array(@user.status&.errors&.full_messages)
        error(messages.uniq.join('. '))
      end
    end

    private

    def assign_attributes
      @user.assign_attributes(params) unless params.empty?
    end

    def custom_validations
      @user.errors.add(:base, 'Please fill in your full name') if @user.name.blank?
      @user.errors.add(:base, 'Please select your role') if @user.role.blank?
      @user.errors.add(:base, 'Please answer "Are you setting up GitLab for a company?"') if @user.setup_for_company.nil?
    end
  end
end
