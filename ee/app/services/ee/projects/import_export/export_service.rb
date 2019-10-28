# frozen_string_literal: true

module EE::Projects::ImportExport::ExportService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  private

  override :exporters
  def exporters
    super + Array.wrap(design_repo_saver)
  end

  def design_repo_saver
    Gitlab::ImportExport::DesignRepoSaver.new(project: project, shared: shared)
  end
end
