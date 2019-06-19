# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Commit < Base
          def title
            n_('Commit', 'Commits', value)
          end

          # I'm not sure how iterating per project on gitaly service will perform,
          # I propose not to show commits per group for MVC
          def value
            0
          end
        end
      end
    end
  end
end
