# frozen_string_literal: true

module Gitlab
  module HookData
    class ProjectMemberBuilder < BaseBuilder
      alias_method :project_member, :object

      # Sample data

      # {
      #   :event_name=>"user_add_to_team",
      #   :project_name=>"GitLab Project",
      #   :project_path=>"gitlab",
      #   :project_path_with_namespace=>"namespace/gitlab",
      #   :project_id=>1,
      #   :user_username=>"robert",
      #   :user_name=>"Robert Mills",
      #   :user_email=>"robert@example.com",
      #   :user_id=>14,
      #   :acess_level=>"Developer",
      #   :project_visibility=>"internal",
      #   :created_at=>"2020-11-04T10:12:10Z",
      #   :updated_at=>"2020-11-04T10:12:10Z",
      #   :expires_at=>"2020-12-04T10:12:10Z"
      # }

      def build(event)
        [
          timestamps_data,
          project_member_data,
          event_data(event)
        ].reduce(:merge)
      end

      private

      def project_member_data
        project = project_member.project || Project.unscoped.find(project_member.source_id)

        {
          project_name:                 project.name,
          project_path:                 project.path,
          project_path_with_namespace:  project.full_path,
          project_id:                   project.id,
          user_username:                project_member.user.username,
          user_name:                    project_member.user.name,
          user_email:                   project_member.user.email,
          user_id:                      project_member.user.id,
          access_level:                 project_member.human_access,
          project_visibility:           Project.visibility_levels.key(project.visibility_level_value).downcase
        }
      end

      def event_data(event)
        event_name =  case event
                      when :create
                        'user_add_to_team'
                      when :destroy
                        'user_remove_from_team'
                      when :update
                        'user_update_for_team'
                      end
        { event_name: event_name }
      end
    end
  end
end
