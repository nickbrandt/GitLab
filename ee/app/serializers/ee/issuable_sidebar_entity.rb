# frozen_string_literal: true

module EE
  module IssuableSidebarEntity
    extend ActiveSupport::Concern

    prepended do
      expose :weight, if: ->(issuable, options) { issuable.supports_weight? }
    end
  end
end
