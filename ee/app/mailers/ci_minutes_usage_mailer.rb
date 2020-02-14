# frozen_string_literal: true

class CiMinutesUsageMailer < ApplicationMailer
  def notify(namespace_name, recipients)
    @namespace_name = namespace_name

    mail(
      bcc: recipients,
      subject: "GitLab CI Runner Minutes quota for #{namespace_name} has run out"
    )
  end

  def notify_limit(namespace_name, recipients, percentage_of_available_mins)
    @namespace_name = namespace_name
    @percentage_of_available_mins = percentage_of_available_mins

    mail(
      bcc: recipients,
      subject: "GitLab CI Runner Minutes quota for #{namespace_name} has \
                less than #{percentage_of_available_mins}% available"
    )
  end
end
