# frozen_string_literal: true

class NewEpicWorker
  include ApplicationWorker
  include NewIssuable

  feature_category :agile_portfolio_management

  def perform(epic_id, user_id)
    return unless objects_found?(epic_id, user_id)

    EventCreateService.new.open_epic(issuable, user)
    NotificationService.new.new_epic(issuable)
    issuable.create_cross_references!(user)
  end

  def issuable_class
    Epic
  end
end
