# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      class PushRuleCheck < ::Gitlab::Checks::BaseChecker
        def validate!
          return unless push_rule

          if tag_name
            PushRules::TagCheck.new(change_access).validate!
          else
            PushRules::BranchCheck.new(change_access).validate!
          end

          PushRules::FileSizeCheck.new(change_access).validate!
        end
      end
    end
  end
end
