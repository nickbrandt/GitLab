# frozen_string_literal: true

module EE
  module IssueSidebarExtrasEntity
    extend ActiveSupport::Concern

    prepended do
      expose :epic do
        expose :epic, merge: true, using: EpicBaseEntity
        expose :epic_issue_id do |issuable|
          issuable.epic_issue&.id
        end
      end
      expose :weight
    end
  end
end
