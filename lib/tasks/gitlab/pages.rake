# frozen_string_literal: true

namespace :gitlab do
  namespace :pages do
    # TODO: Remove after execution on gitlab.com https://gitlab.com/gitlab-org/gitlab/issues/34018
    desc 'Fixes pages access control settings for gitlab.com(see https://gitlab.com/gitlab-org/gitlab/issues/32961)'

    task fix_pages_access_control_setting_on_gitlab_com: :environment do
      ::Gitlab::BackgroundMigration::FixGitlabComPagesAccessLevel.new.perform
    end
  end
end
