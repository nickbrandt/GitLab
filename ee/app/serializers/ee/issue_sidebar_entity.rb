# frozen_string_literal: true

module EE
  module IssueSidebarEntity
    extend ActiveSupport::Concern

    prepended do
      expose :epic, using: EpicBaseEntity
    end
  end
end
