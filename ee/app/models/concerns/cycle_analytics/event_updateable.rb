# frozen_string_literal: true

module CycleAnalytics
  module EventUpdateable
    def assign_event_parameters!
      start_event = params.delete(:start_event)
      if start_event
        params[:start_event_identifier] = start_event[:identifier]
        params[:start_event_label_id] = start_event[:label_id]
      end

      end_event = params.delete(:end_event)
      if end_event
        params[:end_event_identifier] = end_event[:identifier]
        params[:end_event_label_id] = end_event[:label_id]
      end
    end
  end
end
