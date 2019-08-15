# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ProjectMilestone < QA::Resource::Base
        attribute :id
        attribute :title

        attribute :project do
          QA::Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'project-with-milestone'
          end
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "/projects/#{project.id}/milestones/#{id}"
        end

        def api_post_path
          "/projects/#{project.id}/milestones"
        end

        def api_post_body
          {
            title: title
          }
        end
      end
    end
  end
end
