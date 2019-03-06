# frozen_string_literal: true

module AuditEventsHelper
  def human_text(details)
    # replace '_' with " " to achive identical behavior with Audit::Details
    return details[:custom_message].tr('_', ' ') if details[:custom_message]

    details.map { |key, value| select_keys(key, value) }.join(" ").humanize
  end

  def select_keys(key, value)
    if key =~ /^(author|target)_.*/
      ""
    else
      "#{key} <strong>#{value}</strong>"
    end
  end
end
