# frozen_string_literal: true

module JiraImport
  class UsersMapperService
    include Gitlab::Utils::StrongMemoize

    # MAX_USERS must match the pageSize value in app/assets/javascripts/jira_import/utils/constants.js
    MAX_USERS = 50

    # The class is called from UsersImporter and small batches of users are expected
    # In case the mapping of a big batch of users is expected to be passed here
    # the implementation needs to change here and handles the matching in batches
    def initialize(current_user, project, start_at)
      @current_user = current_user
      @project = project
      @jira_service = project.jira_service
      @start_at = start_at
    end

    def execute
      jira_users.to_a.map do |jira_user|
        {
          jira_account_id: jira_user_id(jira_user),
          jira_display_name: jira_user_name(jira_user),
          jira_email: jira_user['emailAddress']
        }.merge(gitlab_id: find_gitlab_id(jira_user))
      end
    end

    private

    attr_reader :current_user, :project, :jira_service, :start_at

    def jira_users
      @jira_users ||= client.get(url)
    end

    def client
      @client ||= jira_service.client
    end

    def url
      raise NotImplementedError
    end

    def jira_user_id(jira_user)
      raise NotImplementedError
    end

    def jira_user_name(jira_user)
      raise NotImplementedError
    end

    def matched_users
      strong_memoize(:matched_users) do
        pairs_to_match = jira_users.map do |user|
          "('#{jira_user_name(user)&.downcase}', '#{user['emailAddress']&.downcase}')"
        end.join(',')

        User.by_emails_or_names(pairs_to_match)
      end
    end

    def find_gitlab_id(jira_user)
      user = matched_users.find do |matched_user|
        matched_user['jira_email'] == jira_user['emailAddress']&.downcase ||
          matched_user['jira_name'].downcase == jira_user_name(jira_user)&.downcase
      end

      return unless user

      user_id = user['user_id']

      return unless project_member_ids.include?(user_id)

      user_id
    end

    def project_member_ids
      # rubocop: disable CodeReuse/ActiveRecord
      @project_member_ids ||= MembersFinder.new(project, current_user).execute.pluck(:user_id)
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
