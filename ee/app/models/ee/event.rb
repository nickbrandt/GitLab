# frozen_string_literal: true

module EE
  module Event
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics

      scope :issues, -> { where(target_type: 'Issue') }
      scope :merge_requests, -> { where(target_type: 'MergeRequest') }
      scope :created, -> { where(action: ::Event::CREATED) }
      scope :closed, -> { where(action: ::Event::CLOSED) }
      scope :merged, -> { where(action: ::Event::MERGED) }
      scope :totals_by_author, -> { group(:author_id).count }
      scope :totals_by_author_target_type_action, -> { group(:author_id, :target_type, :action).count }
      scope :epics, -> { where(target_type: 'Epic') }
    end

    override :capability
    def capability
      @capability ||= begin
                        if epic? || epic_note?
                          :read_epic
                        else
                          super
                        end
                      end
    end

    def epic_note?
      note? && note_target.is_a?(::Epic)
    end

    def epic?
      target_type == 'Epic'
    end
  end
end
