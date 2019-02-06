# frozen_string_literal: true

# When this file is eager-loaded **before `issuable/clone/base_service.rb`**, the
# `Issuable::Clone::BaseService` constant is defined (in this file) as a module,
# making subsequent inheritance from `::Issuable::Clone::BaseService` (e.g. in
# `EE::IssuePromoteService`) failing with a "TypeError: superclass must be a
# Class (Module given)" error.
# Explicitely requiring `issuable/clone/base_service.rb` makes sure that the
# correct `::Issuable::Clone::BaseService` constant is defined first.
require_dependency 'issuable/clone/base_service' if Rails.configuration.eager_load

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

# When this file is eager-loaded, since we explicitely require
# `issuable/clone/base_service.rb` above, we cannot perform the prepend in
# `issuable/clone/base_service.rb` otherwise we'd get a circular dependency
# error. Thus we perform the prepend in this file, after
# `Issuable::Clone::BaseService` and `EE::Issuable::Clone::BaseService` are defined.
Issuable::Clone::BaseService.prepend(EE::Issuable::Clone::BaseService) if Rails.configuration.eager_load
