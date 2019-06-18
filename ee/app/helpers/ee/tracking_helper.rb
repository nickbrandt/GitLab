# frozen_string_literal: true

module EE
  module TrackingHelper
    extend ::Gitlab::Utils::Override

    override :tracking_attrs
    def tracking_attrs(label, event, property)
      return {} unless tracking_enabled?

      {
        data: {
          track_label: label,
          track_event: event,
          track_property: property
        }
      }
    end

    private

    def tracking_enabled?
      Rails.env.production? &&
        ::Gitlab::CurrentSettings.snowplow_enabled?
    end
  end
end
