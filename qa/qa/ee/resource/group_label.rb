# frozen_string_literal: true

require 'securerandom'

module QA
  module EE
    module Resource
      class GroupLabel < Base
        attr_accessor :description, :color

        attribute :id
        attribute :title

        attribute :group do
          Group.fabricate_via_api! do |resource|
            resource.name = 'group-with-label'
          end
        end

        def initialize
          @title = "qa-test-#{SecureRandom.hex(8)}"
          @description = 'This is a test group label'
          @color = '#6655FF'
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          raise NotImplementedError, "The Labels API doesn't expose a single-resource endpoint so this method cannot be properly implemented."
        end

        def api_post_path
          "/groups/#{group.id}/labels"
        end

        def api_post_body
          {
            color: @color,
            name: @title,
            description: @description
          }
        end
      end
    end
  end
end
