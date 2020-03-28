# frozen_string_literal: true

module StatusPage
  # Convenient method to trigger a status page update.
  def self.trigger_publish(project, user, triggered_by)
    TriggerPublishService.new(project, user, triggered_by).execute
  end
end
