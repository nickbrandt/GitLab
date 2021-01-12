# frozen_string_literal: true

module EE
  module Emails
    module Members
      def member_access_granted_email_with_confirmation(member_id)
        @member_id = member_id

        return unless member_exists?

        @user = member.user

        member_email_with_layout(
          to: member.user.email,
          subject: subject("Welcome to GitLab"))
      end
    end
  end
end
