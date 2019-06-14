# frozen_string_literal: true

module EE
  module Types
    module Notes
      module NoteableType
        extend ::Gitlab::Utils::Override

        override :resolve_type
        def resolve_type(object, context)
          case object
          when DesignManagement::Design
            ::Types::DesignManagement::DesignType
          else
            super
          end
        end
      end
    end
  end
end
