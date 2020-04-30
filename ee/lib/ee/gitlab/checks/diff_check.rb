# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module DiffCheck
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        def path_validations
          validations = [super].flatten

          if project.branch_requires_code_owner_approval?(branch_name)
            validations << validate_code_owners
          end

          validations
        end

        def validate_code_owners
          lambda do |paths|
            loader = ::Gitlab::CodeOwners::Loader.new(project, branch_name, paths)

            return if loader.entries.blank?
            return if loader.members.include?(change_access.user_access.user)

            assemble_error_msg_for_codeowner_matches(loader)
          end
        end

        def assemble_error_msg_for_codeowner_matches(loader)
          matched_rules = loader.entries.collect { |e| "- #{e.pattern}" }
          code_owner_path = project.repository.code_owners_blob(ref: branch_name).path || "CODEOWNERS"

          msg = "Pushes to protected branches that contain changes to files that\n" \
            "match patterns defined in `#{code_owner_path}` are disabled for\n" \
            "this project. Please submit these changes via a merge request.\n\n" \
            "The following pattern(s) from `#{code_owner_path}` were matched:\n" \
            "#{matched_rules.join('\n')}\n"

          updated_from_web? ? msg.tr("\n", " ") : msg
        end

        def validate_path_locks?
          strong_memoize(:validate_path_locks) do
            project.feature_available?(:file_locks) &&
              project.any_path_locks? &&
              project.default_branch == branch_name # locks protect default branch only
          end
        end

        def push_rule_checks_commit?
          return false unless push_rule

          push_rule.file_name_regex.present? || push_rule.prevent_secrets
        end

        override :validations_for_diff
        def validations_for_diff
          super.tap do |validations|
            validations.push(path_locks_validation) if validate_path_locks?
            validations.push(file_name_validation) if push_rule_checks_commit?
          end
        end

        def path_locks_validation
          lambda do |diff|
            path = if diff.renamed_file?
                     diff.old_path
                   else
                     diff.new_path || diff.old_path
                   end

            lock_info = project.find_path_lock(path)

            if lock_info && lock_info.user != user_access.user
              return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
            end
          end
        end

        def file_name_validation
          lambda do |diff|
            if (diff.renamed_file || diff.new_file) && blacklisted_regex = push_rule.filename_blacklisted?(diff.new_path)
              return unless blacklisted_regex.present?

              "File name #{diff.new_path} was blacklisted by the pattern #{blacklisted_regex}."
            end
          rescue ::PushRule::MatchError => e
            raise ::Gitlab::GitAccess::ForbiddenError, e.message
          end
        end
      end
    end
  end
end
