# frozen_string_literal: true

class Import::ProviderRepoSerializer < BaseSerializer
  def represent(repo, opts = {})
    entity =
      case opts[:provider]
      when :fogbugz
        Import::FogbugzProviderRepoEntity
      when :github, :gitea
        Import::GithubishProviderRepoEntity
      when :bitbucket
        Import::BitbucketProviderRepoEntity
      when :bitbucket_server
        Import::BitbucketServerProviderRepoEntity
      else
        raise NotImplementedError
      end

    super(repo, opts, entity)
  end
end
