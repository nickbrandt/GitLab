# frozen_string_literal: true

module EE
  module Gitlab
    module UrlBuilder
      extend ::Gitlab::Utils::Override

      override :url
      def url
        case object
        when ::DesignManagement::Design
          design_url
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

      private

      def design_url
        size, ref = opts.values_at(:size, :ref)
        design = object

        if size
          project_design_management_designs_resized_image_url(design.project, design, ref, size)
        else
          project_design_management_designs_raw_image_url(design.project, design, ref)
        end
      end
    end
  end
end
