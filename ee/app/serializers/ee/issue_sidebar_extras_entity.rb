# frozen_string_literal: true

module EE
  module IssueSidebarExtrasEntity
    extend ActiveSupport::Concern

    prepended do
      expose :epic, using: EpicBaseEntity
      expose :weight
    end
  end
end
