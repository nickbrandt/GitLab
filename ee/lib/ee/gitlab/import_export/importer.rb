# frozen_string_literal: true

module EE::Gitlab::ImportExport::Importer
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  private

  override :restorers
  def restorers
    super + Array.wrap(design_repo_restorer)
  end

  def design_repo_restorer
    return unless Feature.enabled?(:export_designs, project, default_enabled: true)

    Gitlab::ImportExport::DesignRepoRestorer.new(
      path_to_bundle: design_repo_path,
      shared: shared,
      project: project
    )
  end

  def design_repo_path
    File.join(shared.export_path, ::Gitlab::ImportExport.design_repo_bundle_filename)
  end
end
