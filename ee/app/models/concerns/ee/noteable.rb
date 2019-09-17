# frozen_string_literal: true

module EE
  module Noteable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    class_methods do
      # We can't specify `override` here:
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/50911
      def replyable_types
        super + %w(Epic)
      end

      def resolvable_types
        super + %w(DesignManagement::Design)
      end
    end

    override :note_etag_key
    def note_etag_key
      case self
      when Epic
        ::Gitlab::Routing.url_helpers.group_epic_notes_path(group, self)
      when DesignManagement::Design
        ::Gitlab::Routing.url_helpers.designs_project_issue_path(project, issue, { vueroute: filename })
      else
        super
      end
    end

    def after_note_created(_note)
      # no-op
    end

    def after_note_destroyed(_note)
      # no-op
    end
  end
end
