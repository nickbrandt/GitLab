# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccess
      prepend GeoGitAccess
      extend ::Gitlab::Utils::Override
      include ActionView::Helpers::SanitizeHelper
      include PathLocksHelper

      override :check
      def check(cmd, changes)
        check_geo_license!
        check_smartcard_access!

        super
      end

      override :can_read_project?
      def can_read_project?
        return true if geo?

        super
      end

      protected

      override :user
      def user
        return if geo?

        super
      end

      private

      override :check_custom_action
      def check_custom_action(cmd)
        custom_action = custom_action_for(cmd)
        return custom_action if custom_action

        super
      end

      override :check_for_console_messages
      def check_for_console_messages(cmd)
        super.push(
          *current_replication_lag_message
        )
      end

      override :check_download_access!
      def check_download_access!
        return if geo?

        super
      end

      override :check_change_access!
      def check_change_access!
        check_size_before_push!

        check_if_license_blocks_changes!

        super

        check_push_size!
      end

      override :check_active_user!
      def check_active_user!
        return if geo?

        super
      end

      def check_geo_license!
        if ::Gitlab::Geo.secondary? && !::Gitlab::Geo.license_allows?
          raise ::Gitlab::GitAccess::UnauthorizedError, 'Your current license does not have GitLab Geo add-on enabled.'
        end
      end

      def check_smartcard_access!
        unless can_access_without_new_smartcard_login?
          raise ::Gitlab::GitAccess::UnauthorizedError, 'Project requires smartcard login. Please login to GitLab using a smartcard.'
        end
      end

      def can_access_without_new_smartcard_login?
        return true unless user

        !::Gitlab::Auth::Smartcard::SessionEnforcer.new.access_restricted?(user)
      end

      def geo?
        actor == :geo
      end

      def check_size_before_push!
        if check_size_limit? && project.above_size_limit?
          raise ::Gitlab::GitAccess::UnauthorizedError, ::Gitlab::RepositorySizeError.new(project).push_error
        end
      end

      def check_if_license_blocks_changes!
        if ::License.block_changes?
          message = ::LicenseHelper.license_message(signed_in: true, is_admin: (user && user.admin?))
          raise ::Gitlab::GitAccess::UnauthorizedError, strip_tags(message)
        end
      end

      def check_push_size!
        return unless check_size_limit?

        # If there are worktrees with a HEAD pointing to a non-existent object,
        # calls to `git rev-list --all` will fail in git 2.15+. This should also
        # clear stale lock files.
        project.repository.clean_stale_repository_files

        # Use #check_repository_disk_size to get correct push size whenever a lot of changes
        # gets pushed at the same time containing the same blobs. This is only
        # doable if GIT_OBJECT_DIRECTORY_RELATIVE env var is set and happens
        # when git push comes from CLI (not via UI and API).
        #
        # Fallback to determining push size using the changes_list so we can still
        # determine the push size if env var isn't set (e.g. changes are made
        # via UI and API).
        if check_quarantine_size?
          check_repository_disk_size
        else
          check_changes_size
        end
      end

      def check_quarantine_size?
        git_env = ::Gitlab::Git::HookEnv.all(repository.gl_repository)

        git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
      end

      def check_repository_disk_size
        check_size_against_limit(project.repository.object_directory_size)
      end

      def check_changes_size
        changes_size = 0

        changes_list.each do |change|
          changes_size += repository.new_blobs(change[:newrev]).sum(&:size) # rubocop: disable CodeReuse/ActiveRecord

          check_size_against_limit(changes_size)
        end
      end

      def check_size_against_limit(size)
        if project.changes_will_exceed_size_limit?(size)
          raise ::Gitlab::GitAccess::UnauthorizedError, ::Gitlab::RepositorySizeError.new(project).new_changes_error
        end
      end

      def check_size_limit?
        strong_memoize(:check_size_limit) do
          project.size_limit_enabled? &&
            changes_list.any? { |change| !::Gitlab::Git.blank_ref?(change[:newrev]) }
        end
      end
    end
  end
end
