# frozen_string_literal: true

module MultiUser
  extend ActiveSupport::Concern

  class_methods do
    # Allow the current action to define a new warden session.
    # Retain the previous warden session if the current action does nothing.
    def multi_user_login(options)
      options[:unless] = :ignore_user_login?
      prepend_before_action :enable_multi_user_login, options
    end

    def multi_user_logout(options)
      prepend_before_action :enable_multi_user_logout, options
    end
  end

  def ignore_user_login?
    # One time password exception.
    session.has_key? :otp_user_id
  end

  def enable_multi_user_login
    @multi_user_action ||= :login
  end

  def enable_multi_user_logout
    @multi_user_action ||= :logout
  end

  # Call this method in an around filter to handle multi-user warden sessions.
  # Must be specified after session storage has been defined.
  def multi_user_handler(&blk)
    case multi_user_action
    when :login
      wrap_login_action(&blk)
    when :logout
      wrap_logout_action(&blk)
    else
      yield
    end
  end

  private

  attr_accessor :multi_user_action

  def wrap_login_action(&blk)
    # Archive and move the current warden session out of the way.
    if previous_user = current_user
      Gitlab::WardenSession.save
      sign_out_quietly(previous_user)
    end

    # Run the login action. An invalid login will raise an exception.
    yield

    # Save the new authorized user in to our register.
    Gitlab::WardenSession.save
  ensure
    # Load the previous active warden session if no new session.
    if current_user.nil? && previous_user
      Gitlab::WardenSession.load(previous_user.id)
      bypass_sign_in(previous_user)
    end
  end

  # Sign out the user from Warden (and Devise) without callbacks.
  # A modified copy of #sign_out from Devise without callbacks.
  def sign_out_quietly(user)
    # Sign the current user out for now.
    warden.logout(user)
    scope = Devise::Mapping.find_scope!(user)
    warden.clear_strategies_cache!(scope: scope)
    # Devise does not provide a cleaner way to define the @current_user so we
    # must explicitly nullify the instance variable ourselves.
    @current_user = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def wrap_logout_action(&blk)
    Gitlab::WardenSession.delete(current_user.id)
    yield
  end
end
