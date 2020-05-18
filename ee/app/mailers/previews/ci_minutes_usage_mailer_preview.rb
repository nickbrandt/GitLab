# frozen_string_literal: true

class CiMinutesUsageMailerPreview < ActionMailer::Preview
  def out_of_minutes
    ::CiMinutesUsageMailer.notify('GROUP_NAME', %w(bob@example.com))
  end

  def limit_warning
    ::CiMinutesUsageMailer.notify_limit('GROUP_NAME', %w(bob@example.com), 30)
  end
end
