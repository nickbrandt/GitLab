# frozen_string_literal: true

module StatusPage
  # Corresponds to an issue which has been published to a
  # status-page app's AWS bucket.
  class PublishedIncident < ApplicationRecord
    self.table_name = "status_page_published_incidents"

    belongs_to :issue, inverse_of: :status_page_published_incident
    validates :issue, presence: true
  end
end
