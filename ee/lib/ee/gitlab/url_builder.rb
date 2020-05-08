# frozen_string_literal: true

module EE
  module Gitlab
    module UrlBuilder
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :build
        def build(object, **options)
          case object.itself
          when Epic
            instance.group_epic_url(object.group, object, **options)
          when Vulnerability
            instance.project_security_vulnerability_url(object.project, object, **options)
          else
            super
          end
        end

        override :note_url
        def note_url(note, **options)
          noteable = note.noteable

          if note.for_epic?
            instance.group_epic_url(noteable.group, noteable, anchor: dom_id(note), **options)
          elsif note.for_vulnerability?
            instance.project_security_vulnerability_url(noteable.project, noteable, anchor: dom_id(note), **options)
          else
            super
          end
        end

        override :wiki_url
        def wiki_url(object, **options)
          if object.container.is_a?(Group)
            # TODO: Use the new route for group wikis once we add it.
            # https://gitlab.com/gitlab-org/gitlab/-/issues/211360
            instance.group_canonical_url(object.container, **options) + "/-/wikis/#{::Wiki::HOMEPAGE}"
          else
            super
          end
        end
      end
    end
  end
end
