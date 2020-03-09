# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Evidence < Grape::Entity
        expose :summary_sha, as: :sha
        expose :filepath
        expose :collected_at

        def filepath
          release = object.release
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
  end
end
