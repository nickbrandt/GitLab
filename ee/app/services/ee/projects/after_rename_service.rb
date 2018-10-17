# frozen_string_literal: true

module EE::Projects::AfterRenameService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :rename_or_migrate_repository!
  def rename_or_migrate_repository!
    super

    ::Geo::RepositoryRenamedEventStore.new(
      project,
      old_path: path_before,
      old_path_with_namespace: full_path_before
    ).create!
  end
end
