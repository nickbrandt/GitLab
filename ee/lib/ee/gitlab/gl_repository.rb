# frozen_string_literal: true

module EE
  module Gitlab
    module GlRepository
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      DESIGN = ::Gitlab::GlRepository::RepoType.new(
        name: :design,
        access_checker_class: ::Gitlab::GitAccessDesign,
        repository_resolver: -> (project) { ::DesignManagement::Repository.new(project) },
        suffix: :design
      )

      EE_TYPES = {
        DESIGN.name.to_s => DESIGN
      }.freeze

      override :types
      def types
        super.merge(EE_TYPES)
      end
    end
  end
end
