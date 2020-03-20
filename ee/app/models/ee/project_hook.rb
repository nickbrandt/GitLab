# frozen_string_literal: true

module EE
  module ProjectHook
    extend ActiveSupport::Concern

    prepended do
      include CustomModelNaming

      self.singular_route_key = :hook
    end
  end
end
