# frozen_string_literal: true

module EE
  module API
    module Commits
      extend ActiveSupport::Concern

      prepended do
        helpers do
          def authorize_push_to_branch!(branch)
            super

            codeowners_check_result = check_against_codeowners(user_project, branch, extracted_paths)

            if codeowners_check_result
              forbidden!(codeowners_check_result)
            end
          end

          def check_against_codeowners(project, branch, paths)
            return unless ::ProtectedBranch.branch_requires_code_owner_approval?(project, branch)
            return unless paths

            codeowners_violations = ::Gitlab::CodeOwners::Validator.new(project, branch, paths).execute

            return unless codeowners_violations

            codeowners_violations
          end

          def extracted_paths
            return unless params[:actions]

            params[:actions].flat_map { |entry| [entry[:file_path], entry[:previous_path]] }.compact.uniq
          end
        end
      end
    end
  end
end
