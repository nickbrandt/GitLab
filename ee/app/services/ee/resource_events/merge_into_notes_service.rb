# frozen_string_literal: true

module EE
  module ResourceEvents
    module MergeIntoNotesService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :synthetic_notes
      def synthetic_notes
        super + SyntheticWeightNotesBuilderService.new(resource, current_user, params).execute
      end
    end
  end
end
