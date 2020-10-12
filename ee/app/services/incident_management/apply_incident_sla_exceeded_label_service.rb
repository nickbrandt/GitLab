# frozen_string_literal: true

module IncidentManagement
  class ApplyIncidentSlaExceededLabelService < BaseService
    def initialize(incident)
      super(incident.project)

      @incident = incident
      @label = incident_exceeded_sla_label
    end

    def execute
      return if incident.label_ids.include?(label.id)

      incident.labels << label
      add_resource_event

      label
    end

    private

    attr_reader :incident, :label

    def add_resource_event
      ResourceEvents::ChangeLabelsService
        .new(incident, User.alert_bot)
        .execute(added_labels: [label])
    end

    def incident_exceeded_sla_label
      ::IncidentManagement::CreateIncidentSlaExceededLabelService
        .new(project)
        .execute
        .payload[:label]
    end
  end
end
