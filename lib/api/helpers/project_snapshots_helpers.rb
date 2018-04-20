module API
  module Helpers
    module ProjectSnapshotsHelpers
<<<<<<< HEAD
      prepend ::EE::API::Helpers::ProjectSnapshotsHelpers

=======
>>>>>>> 64be2046a655cced89ff7c7f5b289a68e105fad9
      def authorize_read_git_snapshot!
        authenticated_with_full_private_access!
      end

      def send_git_snapshot(repository)
        header(*Gitlab::Workhorse.send_git_snapshot(repository))
      end

      def snapshot_project
        user_project
      end

      def snapshot_repository
        if to_boolean(params[:wiki])
          snapshot_project.wiki.repository
        else
          snapshot_project.repository
        end
      end
    end
  end
end
