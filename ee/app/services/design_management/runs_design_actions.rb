# frozen_string_literal: true

module DesignManagement
  module RunsDesignActions
    # this concern requires the following methods to be implemented:
    #   current_user, target_branch, repository, commit_message
    def run_actions(actions)
      repository.create_if_not_exists
      sha = repository.multi_action(current_user,
                                    branch_name: target_branch,
                                    message: commit_message,
                                    actions: actions.map(&:gitaly_action))

      ::DesignManagement::Version.create_for_designs(actions, sha)
    end
  end
end
