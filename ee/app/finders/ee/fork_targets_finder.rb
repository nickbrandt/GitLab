# frozen_string_literal: true

module EE
  module ForkTargetsFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :execute
    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      targets = super

      root_group = project.group&.root_ancestor

      return targets unless root_group&.saml_provider

      if root_group.saml_provider.prohibited_outer_forks?
        targets = targets.where(id: root_group.self_and_descendants)
      end

      targets
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
