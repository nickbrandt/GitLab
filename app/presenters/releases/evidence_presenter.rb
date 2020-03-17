# frozen_string_literal: true

module Releases
  class EvidencePresenter < Gitlab::View::Presenter::Simple
    presents :evidence

    def filepath
      release = evidence.release
      project = release.project

      Gitlab::Routing.url_helpers.namespace_project_evidence_url(
        namespace_id: project.namespace,
        project_id: project,
        tag: release,
        id: object.id,
        format: :json)
    end
  end
end