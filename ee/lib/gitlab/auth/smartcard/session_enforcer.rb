# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class SessionEnforcer
        def update_session
          session.update_active(DateTime.now)
        end

        def access_restricted?(user)
          return false unless ::Gitlab::Auth::Smartcard.required_for_git_access?

          !active_session?(user)
        end

        private

        def session
          @session ||= Smartcard::Session.new
        end

        def active_session?(user)
          session.active?(user)
        end
      end
    end
  end
end
