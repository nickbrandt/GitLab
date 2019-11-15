# frozen_string_literal: true

module EE
  module NoteEntity
    extend ActiveSupport::Concern

    prepended do
      with_options if: -> (note, _) { note.system? && note.resource_parent.feature_available?(:description_diffs) } do
        expose :description_version_id
        expose :description_diff_path, if: -> (_) { description_version_id } do |note|
          description_diff_path(note.noteable, description_version_id)
        end
      end

      private

      def description_version_id
        object.system_note_metadata&.description_version_id
      end
    end
  end
end
