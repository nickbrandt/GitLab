# frozen_string_literal: true

module EE
  module IssuableLinks
    module CreateService
      private

      def around_link(objects)
        # it is important that this is not called after relate_issuables, as it relinks epic to the issuable
        # see EpicLinks::EpicIssues#relate_issuables
        affected_epics = affected_epics(objects)

        yield

        Epics::UpdateDatesService.new(affected_epics).execute unless affected_epics.blank?
      end

      def affected_epics(issues)
        []
      end
    end
  end
end
