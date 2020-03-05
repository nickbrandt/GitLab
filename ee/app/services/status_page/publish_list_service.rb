# frozen_string_literal: true

module StatusPage
  class PublishListService < PublishBaseService
    private

    def publish(issues)
      json = serialize(issues)

      upload(object_key, json)
    end

    def serialize(issues)
      serializer.represent_list(issues)
    end

    def object_key
      StatusPage::Storage.list_path
    end
  end
end
