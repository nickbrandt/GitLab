# frozen_string_literal: true

module StatusPage
  # Render an issue as incident details and publish them to CDN.
  #
  # This is an internal service which is part of
  # +StatusPage::PublishService+ and is not meant to be called directly.
  #
  # Consider calling +StatusPage::PublishService+ instead.
  class PublishDetailsService < PublishBaseService
    private

    def process(issue, user_notes)
      json = serialize(issue, user_notes)
      key = object_key(json)
      return error('Missing object key') unless key

      upload(key, json)
    end

    def serialize(issue, user_notes)
      serializer.represent_details(issue, user_notes)
    end

    def object_key(json)
      id = json[:id]
      return unless id

      StatusPage::Storage.details_path(id)
    end
  end
end
