namespace :gitlab do
  namespace :container_registry do
    desc "GitLab | Container Registry | Configure"
    task configure: :gitlab_environment do
      warn_user_is_not_gitlab

      url = Gitlab.config.registry.api_url
      client = ContainerRegistry::Client.new(url)

      info = client.registry_info
      raise 'Failed to detect registry vendor' unless info[:vendor]

      # TODO: update settings on DB
    end
  end
end
