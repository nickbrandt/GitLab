# frozen_string_literal: true

module AuditEventsHelper
  def human_text(details)
    return custom_message_for(details) if details[:custom_message]

    details.map { |key, value| select_keys(key, value) }.join(" ").humanize
  end

  def select_keys(key, value)
    if key =~ /^(author|target)_.*/
      ""
    else
      "#{key} <strong>#{value}</strong>"
    end
  end

  def custom_message_for(details)
    target_type = details[:target_type]
    val = details[:custom_message]
    target_type == 'Operations::FeatureFlag' ? val : val.tr('_', ' ')
  end
end
