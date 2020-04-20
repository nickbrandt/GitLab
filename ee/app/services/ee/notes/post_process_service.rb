# frozen_string_literal: true

module EE
  module Notes
    module PostProcessService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        ::Analytics::RefreshCommentsData.for_note(note)&.execute

        ::SystemNoteService.design_discussion_added(note) if create_design_discussion_system_note?
      end

      private

      def create_design_discussion_system_note?
        note && note.for_design? && note.start_of_discussion?
      end
    end
  end
end
