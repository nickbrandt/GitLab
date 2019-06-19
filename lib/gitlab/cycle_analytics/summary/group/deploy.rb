# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Deploy < Base
          def title
            n_('Deploy', 'Deploys', value)
          end

          def value
            @value ||= Deployment.joins(:project)
              .where(projects: { namespace_id: @group.id })
              .where("deployments.created_at > ?", @from)
              .success
              .count
          end
        end
      end
    end
  end
end
