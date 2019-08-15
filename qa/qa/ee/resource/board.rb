# frozen_string_literal: true

module QA
  module EE
    module Resource
      class Board < QA::Resource::Base
        attribute :id
        attribute :name

        attribute :project do
          QA::Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'project-with-board'
          end
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "/projects/#{project.id}/boards/#{id}"
        end

        def api_post_path
          "/projects/#{project.id}/boards"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
