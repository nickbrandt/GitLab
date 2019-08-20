# frozen_string_literal: true

module EE
  module Note
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ::ObjectStorage::BackgroundMove
      include Elastic::NotesSearch

      belongs_to :review, inverse_of: :notes

      scope :searchable, -> { where(system: false).includes(:noteable) }
    end

    # Original method in Elastic::ApplicationSearch
    def searchable?
      !system && super
    end

    def for_epic?
      noteable.is_a?(Epic)
    end

    override :for_project_noteable?
    def for_project_noteable?
      !for_epic? && super
    end

    override :banzai_render_context
    def banzai_render_context(field)
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    override :mentionable_params
    def mentionable_params
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    override :for_issuable?
    def for_issuable?
      for_epic? || super
    end

    def for_design?
      noteable.is_a?(DesignManagement::Design)
    end

    override :parent
    def parent
      for_epic? ? noteable.group : super
    end

    override :visible_for?
    def visible_for?(user)
      return false unless super

      return true unless system_note_for_epic? && created_before_noteable?

      group_reporter?(user, noteable.group)
    end

    private

    def system_note_for_epic?
      for_epic? && system?
    end

    def created_before_noteable?
      created_at.to_i < noteable.created_at.to_i
    end

    def group_reporter?(user, group)
      group.max_member_access_for_user(user) >= ::Gitlab::Access::REPORTER
    end

    def banzai_context_params
      { group: noteable.group, label_url_method: :group_epics_url }
    end
  end
end
