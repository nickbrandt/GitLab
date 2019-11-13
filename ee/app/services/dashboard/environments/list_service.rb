# frozen_string_literal: true

module Dashboard
  module Environments
    class ListService
      def initialize(user)
        @user = user
      end

      def execute
        load_projects(user)
      end

      private

      attr_reader :user

      def load_projects(user)
        ::Dashboard::Operations::ProjectsService
          .new(user)
          .execute(user.ops_dashboard_projects)
      end
    end
  end
end
