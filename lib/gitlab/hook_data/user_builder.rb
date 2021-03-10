# frozen_string_literal: true

module Gitlab
  module HookData
    class UserBuilder < BaseBuilder
      alias_method :user, :object

      # Sample data

      def build(event)
        [
          timestamps_data,
          event_data(event),
          user_data,
          event_specific_user_data(event)
        ].reduce(:merge)
      end

      private

      def user_data
        {
          name: user.name,
          email: user.email,
          user_id: user.id,
          username: user.username
        }
      end

      def event_specific_user_data(event)
        event_name =  case event
                      when :rename
                        old_username: user.username_before_last_save
                      when :failed_login
                        state: user.state
                      end
        { event_name: event_name }
      end
    end
  end
end
