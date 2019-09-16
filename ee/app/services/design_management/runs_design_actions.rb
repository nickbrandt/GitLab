# frozen_string_literal: true

module DesignManagement
  module RunsDesignActions
    MAX_TRIES = 3

    NoActions = Class.new(StandardError)

    # this concern requires the following methods to be implemented:
    #   current_user, target_branch, repository, commit_message
    #
    # @raise [NoActions] if actions are empty
    def run_actions(actions, tries = MAX_TRIES)
      raise NoActions if actions.empty?

      repository.create_if_not_exists
      sha = repository.multi_action(current_user,
                                    branch_name: target_branch,
                                    message: commit_message,
                                    actions: actions.map(&:gitaly_action))

      ::DesignManagement::Version.create_for_designs(actions, sha)
    rescue Gitlab::Git::CommandError => e
      retry_or_fail(actions, e, tries)
    end

    private

    def retry_or_fail(actions, error, tries)
      if tries < MAX_TRIES
        run_actions(actions, tries - 1)
      else
        raise error
      end
    end
  end
end
