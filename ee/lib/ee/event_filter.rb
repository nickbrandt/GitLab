# frozen_string_literal: true

module EE
  module EventFilter
    extend ::Gitlab::Utils::Override

    EPIC = 'epic'

    override :apply_filter
    def apply_filter(events)
      case filter
      when EPIC
        events.epics
      else
        super
      end
    end

    private

    override :filters
    def filters
      super << EPIC
    end
  end
end
