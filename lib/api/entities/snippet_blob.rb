# frozen_string_literal: true

module API
  module Entities
    class SnippetBlob < Grape::Entity
      expose :path
      expose :raw_url do |blob|
        Gitlab::UrlBuilder.build(blob)
      end
    end
  end
end
