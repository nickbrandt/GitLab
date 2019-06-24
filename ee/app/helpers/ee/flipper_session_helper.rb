# frozen_string_literal: true

module EE
  module FlipperSessionHelper
    def flipper_session
      @flipper_session ||= flipper_session_set? ? get_flipper_session : new_flipper_session
    end

    private

    def flipper_session_set?
      session.has_key?(FlipperSession::SESSION_KEY)
    end

    def get_flipper_session
      FlipperSession.new(session[FlipperSession::SESSION_KEY])
    end

    def new_flipper_session
      FlipperSession.new.tap do |flipper_session|
        session[FlipperSession::SESSION_KEY] = flipper_session.id
      end
    end
  end
end
