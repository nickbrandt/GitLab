# frozen_string_literal: true

module EE
  # PoolRepository EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `PoolRepository` model
  module PoolRepository
    extend ActiveSupport::Concern

    prepended do
      delegate :repository, to: :source_project, prefix: true, allow_nil: true
    end
  end
end
