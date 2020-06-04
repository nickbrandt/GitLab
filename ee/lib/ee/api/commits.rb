# frozen_string_literal: true

module EE
  module API
    module Commits
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :authorize_push_to_branch!
          def authorize_push_to_branch!(branch)
            super

            codeowners_error = check_against_codeowners(user_project, branch, extracted_paths)

            if codeowners_error.present?
              forbidden!(codeowners_error)
            end
          end

          def check_against_codeowners(project, branch, paths)
            return unless paths

            codeowners_violations = ::Gitlab::CodeOwners::Validator.new(project, branch, paths).execute

            return unless codeowners_violations

            codeowners_violations
          end

          def extracted_paths
            return paths_from_actions_param if params[:actions]
            return paths_from_sha_param if params[:sha]
          end

          def paths_from_actions_param
            params[:actions].flat_map do |entry|
              [entry[:file_path], entry[:previous_path]]
            end.compact.uniq
          end

          def paths_from_sha_param
            commit = user_project.commit(params[:sha])
            return unless commit

            commit.raw_deltas.flat_map { |diff| [diff.new_path, diff.old_path] }.uniq
          end
        end
      end
    end
  end
end
