# frozen_string_literal: true

module EE
  class WeightNote < ::Note
    attr_accessor :resource_parent, :event

    def self.from_event(event, resource: nil, resource_parent: nil)
      resource ||= event.issue

      attrs = {
        system: true,
        author: event.user,
        created_at: event.created_at,
        noteable: resource,
        event: event,
        system_note_metadata: ::SystemNoteMetadata.new(action: 'weight'),
        resource_parent: resource_parent
      }

      if resource_parent.is_a?(Project)
        attrs[:project_id] = resource_parent.id
      end

      WeightNote.new(attrs)
    end

    def note
      @note ||= note_text
    end

    def note_html
      @note_html ||= "<p dir=\"auto\">#{note_text(html: true)}</p>"
    end

    def project
      resource_parent if resource_parent.is_a?(Project)
    end

    def group
      resource_parent if resource_parent.is_a?(Group)
    end

    private

    def note_text(html: false)
      weight_text = html ? "<strong>#{event.weight}</strong>" : event.weight
      event.weight ? "changed weight to #{weight_text}" : 'removed the weight'
    end
  end
end
