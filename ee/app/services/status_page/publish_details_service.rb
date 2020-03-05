# frozen_string_literal: true

module StatusPage
  class PublishDetailsService < PublishBaseService
    private

    def publish(issue, user_notes)
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
