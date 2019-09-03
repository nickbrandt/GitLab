# frozen_string_literal: true

module EE
  module LabelNote
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    override :removed_prefix
    def removed_prefix
      if any_label_manually_removed?
        super
      else
        'automatically removed'
      end
    end

    override :added_suffix
    def added_suffix
      scoped_labels_event? ? 'scoped' : super
    end

    def scoped_labels_event?
      events.first.label&.scoped_label?
    end

    # Returns true if a scoped label "remove" event doesn't have a matching "add" event.
    def any_label_manually_removed?
      return true unless scoped_labels_event?

      remove_events = events.select(&:remove?)
      add_events = events.select(&:add?)

      remove_events.any? do |remove_event|
        add_events.none? do |add_event|
          add_event.label.scoped_label_key == remove_event.label.scoped_label_key
        end
      end
    end
  end
end
