# frozen_string_literal: true

module Emails
  module Admin
    def instance_access_request_email(user, recipient)
      @user = user
      @recipient = recipient

      admin_email_with_layout(
        to: recipient.notification_email,
        subject: subject(_("GitLab Account Request")))
    end

    def user_admin_rejection_email(name, email)
      @name = name

      admin_email_with_layout(
        to: email,
        subject: subject(_("GitLab account request rejected")))
    end

    def admin_email_with_layout(to:, subject:, layout: 'mailer')
      mail(to: to, subject: subject) do |format|
        format.html { render layout: layout }
        format.text { render layout: layout }
      end
    end
  end
end
