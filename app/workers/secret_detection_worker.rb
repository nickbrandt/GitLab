# frozen_string_literal: true

class SecretDetectionWorker
  include ApplicationWorker

  AWS_ACCESS_KEY_REGEX = "[^A-Z0-9]([A-Z0-9]{20})[^A-Z0-9]"
  AWS_SECRET_ACCESS_KEY_REGEX = "[^A-Za-z0-9/+=]([A-Za-z0-9/+=]{40})[^A-Za-z0-9/+=]"


  def perform(repository:, gl_repository:, identifier:, changes:, push_options:)
    container, project, repo_type = Gitlab::GlRepository.parse(gl_repository)

    if project.nil? && (!repo_type.snippet? || container.is_a?(ProjectSnippet))
      log("Triggered hook for non-existing project with gl_repository \"#{gl_repository}\"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if ENV['SIDEKIQ_LOG_ARGUMENTS']
    post_received = Gitlab::GitPostReceive.new(container, identifier, changes, push_options)
    Gitlab::GitalyClient::Util.repository()

    if repo_type.project?
      contains_any_secrets?(repository)
    end
  end

  private
  
  def contains_any_secrets?(respository)
    changes = post_received.changes

    changes.each do |change|
      commit = Gitlab::Git::Commit.new(repository, change[:newrev])
      tree = commit.tree
      tree.each_blob do |blob|
        unless blob.binary? do
          blob.load_all_data!(repository)
          return true if blob.data.match?(%r(#{AWS_ACCESS_KEY_REGEX}))
          return true if blob.data.match?(%r(#{AWS_SECRET_ACCESS_KEY_REGEX}))
        end
      end
      return false
    end
  end
end