# frozen_string_literal: true

module EE
  module Gitlab
    module UrlBuilder
      extend ::Gitlab::Utils::Override

      override :url
      def url
        case object
        when DesignManagement::Design
          project_design_url(object.project, object)
        when Epic
          group_epic_url(object.group, object)
        else
          super
        end
      end

      override :note_url
      def note_url
        return super unless object.for_epic?

        epic = object.noteable
        group_epic_url(epic.group, epic, anchor: dom_id(object))
      end
    end
  end
end
