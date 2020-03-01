# frozen_string_literal: true

module EE
  # Repository EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Repository` model
  module Repository
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    MIRROR_REMOTE = "upstream".freeze

    prepended do
      include Elastic::RepositoriesSearch

      delegate :checksum, :find_remote_root_ref, to: :raw_repository
      delegate :pull_mirror_branch_prefix, to: :project
    end

    # Transiently sets a configuration variable
    def with_config(values = {})
      raw_repository.set_config(values)

      yield
    ensure
      raw_repository.delete_config(*values.keys)
    end

    # Runs code after a repository has been synced.
    def after_sync
      expire_all_method_caches
      expire_branch_cache if exists?
      expire_content_cache
    end

    def upstream_branch_name(branch_name)
      return branch_name unless ::Feature.enabled?(:pull_mirror_branch_prefix, project)
      return branch_name unless pull_mirror_branch_prefix

      # when pull_mirror_branch_prefix is set, a branch not starting with it
      # is a local branch that doesn't tracking upstream
      if branch_name.start_with?(pull_mirror_branch_prefix)
        branch_name.delete_prefix(pull_mirror_branch_prefix)
      else
        nil
      end
    end

    def fetch_upstream(url, forced: false)
      add_remote(MIRROR_REMOTE, url)
      fetch_remote(MIRROR_REMOTE, ssh_auth: project&.import_data, forced: forced)
    end

    def upstream_branches
      @upstream_branches ||= remote_branches(MIRROR_REMOTE)
    end

    def diverged_from_upstream?(branch_name)
      with_branch_and_upstream_commit_refs(branch_name, MIRROR_REMOTE) do |branch_commit_ref, upstream_commit_ref|
        branch_exists?(branch_commit_ref) &&
          branch_exists?(upstream_commit_ref) &&
          !raw_repository.ancestor?(branch_commit_ref, upstream_commit_ref)
      end
    end

    def up_to_date_with_upstream?(branch_name)
      with_branch_and_upstream_commit_refs(branch_name, MIRROR_REMOTE) do |branch_commit_ref, upstream_commit_ref|
        ancestor?(branch_commit_ref, upstream_commit_ref)
      end
    end

    override :keep_around
    def keep_around(*shas)
      super
    ensure
      log_geo_updated_event
    end

    override :after_change_head
    def after_change_head
      super
    ensure
      log_geo_updated_event
    end

    def log_geo_updated_event
      return unless ::Gitlab::Geo.primary?

      ::Geo::RepositoryUpdatedService.new(self).execute
    end

    def code_owners_blob(ref: 'HEAD')
      possible_code_owner_blobs = ::Gitlab::CodeOwners::FILE_PATHS.map { |path| [ref, path] }
      blobs_at(possible_code_owner_blobs).compact.first
    end

    def insights_config_for(sha)
      blob_data_at(sha, ::Gitlab::Insights::CONFIG_FILE_PATH)
    end

    private

    def with_branch_and_upstream_commit_refs(branch_name, remote_name)
      upstream_branch = upstream_branch_name(branch_name)
      return false unless upstream_branch

      branch_name = ::Gitlab::Git::BRANCH_REF_PREFIX + branch_name
      upstream_name = "refs/remotes/#{remote_name}/#{upstream_branch}"

      #if branch_exists?(branch_name) && branch_exists?(upstream_name)
        yield branch_name, upstream_name
      #else
      #  return false
      #end
    end
  end
end
