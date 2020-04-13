# frozen_string_literal: true

module EE
  module Mutations
    module ResolvesIssuable
      include ::Mutations::ResolvesGroup
      extend ::Gitlab::Utils::Override

      private

      override :resolve_issuable_parent
      def resolve_issuable_parent(type, parent_path)
        return super unless type == :epic

        resolve_group(full_path: parent_path)
      end
    end
  end
end
