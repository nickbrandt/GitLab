# frozen_string_literal: true

module EE
  module Issuable
    module Clone
      module BaseService
        extend ::Gitlab::Utils::Override

        private

        override :group
        def group
          if new_entity.respond_to?(:group) && new_entity.group
            new_entity.group
          else
            super
          end
        end
      end
    end
  end
end
