# frozen_string_literal: true

module EE
  module Search
    module GroupService
      def elastic_projects
        @elastic_projects ||= projects.pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
      end

      def elastic_global
        false
      end
    end
  end
end
