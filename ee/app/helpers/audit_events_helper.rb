# frozen_string_literal: true

module AuditEventsHelper
  def human_text(details)
    return details[:custom_message] if details[:custom_message]

    details.map { |key, value| select_keys(key, value) }.join(" ").humanize
  end

  def select_keys(key, value)
    if key =~ /^(author|target)_.*/
      ""
    elsif key.to_s == 'ip_address' && value.blank?
      ""
    elsif key =~ /^expiry_(from|to)$/ && value.blank?
      "#{key} <strong>never expires</strong>"
    else
      "#{key} <strong>#{value}</strong>"
    end
  end
end
