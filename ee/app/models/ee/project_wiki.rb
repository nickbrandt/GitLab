# frozen_string_literal: true

module EE
  module ProjectWiki
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include Elastic::WikiRepositoriesSearch
    end

    # No need to have a Kerberos Web url. Kerberos URL will be used only to
    # clone
    def kerberos_url_to_repo
      [::Gitlab.config.build_gitlab_kerberos_url, '/', full_path, '.git'].join('')
    end

    def path_to_repo
      @path_to_repo ||=
        File.join(::Gitlab.config.repositories.storages[project.repository_storage].legacy_disk_path,
                  "#{disk_path}.git")
    end
  end
end
