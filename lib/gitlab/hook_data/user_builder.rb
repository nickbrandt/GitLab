# frozen_string_literal: true

module Gitlab
  module HookData
    class UserBuilder < BaseBuilder
      alias_method :user, :object

      # Sample data
      # {
      # :created_at=>"2021-03-31T10:48:24Z",
      # :updated_at=>"2021-03-31T10:48:24Z",
      # :event_name=>"user_create",
      # :name=>"John Doe",
      # :email=>"john@example.com",
      # :user_id=>2,
      # :username=>"johndoe",
      # :email_opted_in=>"john@example.com",
      # :email_opted_in_ip=>"192.168.1.1",
      # :email_opted_in_source=>"GitLab.com",
      # :email_opted_in_at=>"2021-03-31T10:30:58Z"
      # }

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
        case event
        when :rename
          { old_username: user.username_before_last_save }
        when :failed_login
          { state: user.state }
        else
          {}
        end
      end
    end
  end
end

Gitlab::HookData::UserBuilder.prepend_if_ee('EE::Gitlab::HookData::UserBuilder')
