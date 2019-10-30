# frozen_string_literal: true

module AuditLogsHelper
  def audit_entity_type_options
    [
      { id: 'All', text: 'All Events' },
      { id: 'Group', text: 'Group Events' },
      { id: 'Project', text: 'Project Events' },
      { id: 'User', text: 'User Events' }
    ]
  end

  def audit_entity_type_label(selected)
    selected = 'All' unless selected.present?

    audit_entity_type_options.find { |type| type[:id] == selected }[:text]
  end
end
