# frozen_string_literal: true

class CiMinutesUsageMailer < BaseMailer
  def notify(namespace_name, contact_email)
    @namespace_name = namespace_name

    mail(
      to: contact_email,
      subject: "GitLab CI Runner Minutes quota for #{namespace_name} has run out"
    )
  end
end
