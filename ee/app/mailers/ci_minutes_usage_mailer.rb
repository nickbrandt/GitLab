# frozen_string_literal: true

class CiMinutesUsageMailer < ApplicationMailer
  helper EmailsHelper

  layout 'mailer'

  def notify(namespace_name, recipients)
    @namespace_name = namespace_name

    mail(
      bcc: recipients,
      subject: "Action required: There are no remaining Pipeline minutes for #{namespace_name}"
    )
  end

  def notify_limit(namespace_name, recipients, percentage_of_available_mins)
    @namespace_name = namespace_name
    @percentage_of_available_mins = percentage_of_available_mins

    mail(
      bcc: recipients,
      subject: "Action required: Less than #{percentage_of_available_mins}% " \
               "of Pipeline minutes remain for #{namespace_name}"
    )
  end
end
