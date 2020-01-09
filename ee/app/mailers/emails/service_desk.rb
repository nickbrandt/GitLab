# frozen_string_literal: true

module Emails
  module ServiceDesk
    extend ActiveSupport::Concern

    included do
      layout 'service_desk', only: [:service_desk_thank_you_email, :service_desk_new_note_email]
    end

    def service_desk_thank_you_email(issue_id)
      setup_service_desk_mail(issue_id)

      options = {
        from: sender(@support_bot.id, send_from_user_email: false, sender_name: @project.service_desk_setting&.outgoing_name),
        to: @issue.service_desk_reply_to,
        subject: "Re: #{@issue.title} (##{@issue.iid})"
      }

      mail_new_thread(@issue, options)
    end

    def service_desk_new_note_email(issue_id, note_id)
      @note = Note.find(note_id)
      setup_service_desk_mail(issue_id)

      options = {
        from: sender(@note.author_id),
        to: @issue.service_desk_reply_to,
        subject: "#{@issue.title} (##{@issue.iid})"
      }

      mail_answer_thread(@issue, options)
    end

    private

    def setup_service_desk_mail(issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @support_bot = User.support_bot

      @sent_notification = SentNotification.record(@issue, @support_bot.id, reply_key)
    end
  end
end
