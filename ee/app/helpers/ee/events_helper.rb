# frozen_string_literal: true

module EE
  module EventsHelper
    extend ::Gitlab::Utils::Override

    override :event_note_target_url
    def event_note_target_url(event)
      if event.epic_note?
        group_epic_url(event.group, event.note_target, anchor: dom_id(event.target))
      elsif event.design_note?
        design_url(event.note_target, anchor: dom_id(event.note))
      else
        super
      end
    end

    private

    def design_url(design, opts)
      designs_project_issue_url(
        design.project,
        design.issue,
        opts.merge(vueroute: design.filename)
      )
    end
  end
end
