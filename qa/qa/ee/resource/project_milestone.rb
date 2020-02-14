# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ProjectMilestone < QA::Resource::ProjectMilestone
        attr_writer :start_date, :due_date

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
