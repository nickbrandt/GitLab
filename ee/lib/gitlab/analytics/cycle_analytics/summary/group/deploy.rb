# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class Deploy < Group::Base
            include Gitlab::CycleAnalytics::GroupProjectsProvider

            def title
              n_('Deploy', 'Deploys', value)
            end

            def value
              @value ||= ::Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(deployments_count)
            end

            private

            # rubocop: disable CodeReuse/ActiveRecord
            def deployments_count
              @deployments_count ||= begin
                                       deployments = Deployment.joins(:project).merge(Project.inside_path(group.full_path))
                                       deployments = deployments.where(projects: { id: options[:projects] }) if options[:projects].present?
                                       deployments = deployments.where("deployments.created_at > ?", options[:created_after])
                                       deployments = deployments.where("deployments.created_at < ?", options[:created_before]) if options[:created_before]
                                       deployments.success.count
                                     end
            end
            # rubocop: enable CodeReuse/ActiveRecord
          end
        end
      end
    end
  end
end
