# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class Session
        SESSION_STORE_KEY = :smartcard_signins

        def active?(user)
          sessions = ActiveSession.list_sessions(user)
          sessions.any? do |session|
            Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY, session.with_indifferent_access )['last_signin_at']
          end
        end

        def update_active(value)
          current_session_data['last_signin_at'] = value
        end

        private

        def current_session_data
          Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY)
        end
      end
    end
  end
end
