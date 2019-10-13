# frozen_string_literal: true

module EE
  # PostReceive EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `PostReceive` worker
  module PostReceive
    extend ActiveSupport::Concern

    private

    def after_project_changes_hooks(project, user, refs, changes)
      super

      if audit_push?(project)
        ::RepositoryPushAuditEventWorker.perform_async(changes, project.id, user.id)
      end

      if ::Gitlab::Geo.primary?
        ::Geo::RepositoryUpdatedService.new(project.repository, refs: refs, changes: changes).execute
      end
    end

    def process_wiki_changes(post_received)
      super

      if ::Gitlab::Geo.primary?
        ::Geo::RepositoryUpdatedService.new(post_received.project.wiki.repository).execute
      end
    end

    def audit_push?(project)
      project.push_audit_events_enabled? && !::Gitlab::Database.read_only?
    end
  end
end
