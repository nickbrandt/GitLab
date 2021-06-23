# frozen_string_literal: true

module API
  class GroupAvatar < ::API::Base
    helpers Helpers::GroupsHelpers

    feature_category :subgroups

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the group avatar' do
        detail 'This feature was introduced in GitLab 14.0'
      end
      get ':id/avatar' do
        avatar = user_group.avatar

        not_found!('Avatar') if avatar.blank?

        filename = File.basename(avatar.file.file)

        header(
          'Content-Disposition',
          ActionDispatch::Http::ContentDisposition.format(
            disposition: 'attachment',
            filename: filename
          )
        )

        present_carrierwave_file!(user_group.avatar)
      end
    end
  end
end
