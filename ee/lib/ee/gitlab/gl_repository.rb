# frozen_string_literal: true

module EE
  module Gitlab
    module GlRepository
      extend ActiveSupport::Concern

      DESIGN = ::Gitlab::GlRepository::RepoType.new(
        name: :design,
        access_checker_class: ::Gitlab::GitAccessDesign,
        repository_accessor: -> (project) { ::DesignManagement::Repository.new(project) }
      )

      EE_TYPES = {
        DESIGN.name.to_s => DESIGN
      }.freeze

      class_methods do
        def types
          super.merge(EE_TYPES)
        end
      end
    end
  end
end
