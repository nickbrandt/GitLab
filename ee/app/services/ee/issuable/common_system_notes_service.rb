# frozen_string_literal: true

module EE
  module Issuable
    module CommonSystemNotesService
      extend ::Gitlab::Utils::Override
      attr_reader :issuable

      override :execute
      def execute(_issuable, old_labels: [], is_update: true)
        super

        ActiveRecord::Base.no_touching do
          handle_weight_change(is_update)
          handle_date_change_note if is_update
        end
      end

      private

      def handle_date_change_note
        if issuable.previous_changes.include?('start_date')
          ::SystemNoteService.change_epic_date_note(issuable, current_user, 'start date', issuable['start_date'])
        end

        if issuable.previous_changes.include?('end_date')
          ::SystemNoteService.change_epic_date_note(issuable, current_user, 'finish date', issuable['end_date'])
        end
      end

      def handle_weight_change(is_update)
        return unless issuable.previous_changes.include?('weight')

        if weight_changes_tracking_enabled?
          # Only create a resource event here if is_update is true to exclude the move issue operation.
          # ResourceEvents for moved issues are written within AttributesRewriter.
          EE::ResourceEvents::ChangeWeightService.new([issuable], current_user, Time.now).execute if is_update
        else
          ::SystemNoteService.change_weight_note(issuable, issuable.project, current_user)
        end
      end

      def weight_changes_tracking_enabled?
        !issuable.is_a?(Epic) && ::Feature.enabled?(:track_issue_weight_change_events, issuable.project)
      end
    end
  end
end
