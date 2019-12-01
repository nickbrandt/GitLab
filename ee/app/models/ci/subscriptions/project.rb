# frozen_string_literal: true

module Ci
  module Subscriptions
    class Project < ApplicationRecord
      self.table_name = "ci_subscriptions_projects"

      belongs_to :downstream_project, class_name: '::Project', optional: false
      belongs_to :upstream_project, class_name: '::Project', optional: false

      validates :upstream_project_id, uniqueness: { scope: :downstream_project_id }

      validate do
        errors.add(:upstream_project, 'needs to be public') unless upstream_public?
      end

      private

      def upstream_public?
        upstream_project&.public?
      end
    end
  end
end
