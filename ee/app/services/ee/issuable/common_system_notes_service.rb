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
          handle_weight_change_note
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

      def handle_weight_change_note
        if !issuable.is_a?(Epic) && issuable.previous_changes.include?('weight')
          note = create_weight_change_note

          track_weight_change(note)
        end
      end

      def create_weight_change_note
        ::SystemNoteService.change_weight_note(issuable, issuable.project, current_user)
      end

      def track_weight_change(note)
        return unless weight_changes_tracking_enabled?

        EE::ResourceEvents::ChangeWeightService.new([issuable], current_user, note.created_at).execute
      end

      def weight_changes_tracking_enabled?
        ::Feature.enabled?(:track_issue_weight_change_events, issuable.project)
      end
    end
  end
end
