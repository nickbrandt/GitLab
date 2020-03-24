# frozen_string_literal: true

module EE
  module API
    module Entities
      module IssueBasic
        extend ActiveSupport::Concern

        prepended do
          expose :weight, if: ->(issue, _) { issue.supports_weight? }
        end
      end
    end
  end
end
