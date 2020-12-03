# frozen_string_literal: true

module IncidentManagement
  INCIDENT_LABEL_PROPERTIES = {
    title: 'incident',
    color: '#CC0033',
    description: <<~DESCRIPTION.chomp
      Denotes a disruption to IT services and \
      the associated issues require immediate attention
    DESCRIPTION
  }.freeze
end
