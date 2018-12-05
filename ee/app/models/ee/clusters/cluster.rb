# frozen_string_literal: true

module EE
  module Clusters
    module Cluster
      extend ActiveSupport::Concern

      prepended do
        prepend HasEnvironmentScope

        validate :unique_environment_scope
      end

      def unique_environment_scope
        if project && project.clusters.where(environment_scope: environment_scope).where.not(id: id).exists?
          errors.add(:base, "cannot add duplicated environment scope")
          return false
        end

        if group && group.clusters.where(environment_scope: environment_scope).where.not(id: id).exists?
          errors.add(:base, 'cannot add duplicated environment scope')
          return false
        end

        true
      end
    end
  end
end
