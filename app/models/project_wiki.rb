# frozen_string_literal: true

class ProjectWiki < Wiki
  # TODO: remove container dependency in Wiki
  alias_method :project, :container

  # Project wikis are tied to the main project storage
  delegate :storage, :repository_storage, :hashed_storage?, to: :project

  override :disk_path
  def disk_path(*args, &block)
    project.disk_path + '.wiki'
  end
end

# TODO: Remove this once we implement ES support for group wikis.
# https://gitlab.com/gitlab-org/gitlab/-/issues/207889
ProjectWiki.prepend_if_ee('EE::ProjectWiki')
