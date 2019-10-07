# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ProjectMilestone < QA::Resource::Base
        attr_writer :start_date, :due_date

        attribute :id
        attribute :iid
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
          }.tap do |hash|
            hash[:start_date] = @start_date if @start_date
            hash[:due_date] = @due_date if @due_date
          end
        end
      end
    end
  end
end
